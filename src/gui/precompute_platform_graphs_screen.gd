class_name PrecomputePlatformGraphsScreen
extends Screen


const NAME := "precompute_platform_graphs"
const LAYER_NAME := "menu_screen"
const IS_ALWAYS_ALIVE := false
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

const INITIALIZE_SUB_STEP_PROGRESS_RATIO := 0.04
const PARSE_SUB_STEP_PROGRESS_RATIO := 0.85
const SAVE_SUB_STEP_PROGRESS_RATIO := 0.1
const CLEAN_UP_SUB_STEP_PROGRESS_RATIO := 0.01
const PROGRESS_RATIO_TOTAL := \
        INITIALIZE_SUB_STEP_PROGRESS_RATIO + \
        PARSE_SUB_STEP_PROGRESS_RATIO + \
        SAVE_SUB_STEP_PROGRESS_RATIO + \
        CLEAN_UP_SUB_STEP_PROGRESS_RATIO

var STAGES_TO_DISPLAY_METRICS_FOR := ["parse", "save"]
var stage_to_metric_items := {}

var start_time := -INF
var precompute_level_index := -1
var level_id: String
var platform_graph_parser: PlatformGraphParser
var level: SurfacerLevel


func _init().(
        NAME,
        LAYER_NAME,
        IS_ALWAYS_ALIVE,
        AUTO_ADAPTS_GUI_SCALE,
        INCLUDES_STANDARD_HIERARCHY,
        INCLUDES_NAV_BAR,
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    pass


func _on_activated(previous_screen: Screen) -> void:
    ._on_activated(previous_screen) 
    Gs.time.set_timeout(funcref(self, "_compute"), 0.2)


func _compute() -> void:
    assert(Gs.utils.get_is_pc_device())
    assert(Surfacer.is_precomputing_platform_graphs)
    assert(!Surfacer.precompute_platform_graph_for_levels.empty())
    
    Surfacer.is_inspector_enabled = false
    
    _initialize_metrics()
    
    precompute_level_index = 0
    defer("_initialize_next")


func _initialize_metrics() -> void:
    start_time = Gs.time.get_clock_time()
    
    for stage in STAGES_TO_DISPLAY_METRICS_FOR:
        stage_to_metric_items[stage] = [
            HeaderLabeledControlItem.new(stage),
            StaticTextLabeledControlItem.new("Sum", "-"),
            StaticTextLabeledControlItem.new("Mean", "-"),
            StaticTextLabeledControlItem.new("Min", "-"),
            StaticTextLabeledControlItem.new("Max", "-"),
        ]
    
    var metrics_items := []
    for stage in STAGES_TO_DISPLAY_METRICS_FOR:
        for item in stage_to_metric_items[stage]:
            metrics_items.push_back(item)
    
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Metrics/MetricsList.items = \
            metrics_items


func _initialize_next() -> void:
    Gs.profiler.start("initialize")
    level_id = Surfacer.precompute_platform_graph_for_levels[ \
            precompute_level_index]
    level = Gs.utils.add_scene(
            null,
            Gs.level_config.get_level_config(level_id).scene_path,
            false,
            true)
    Gs.level_session.reset(level_id)
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/LevelWrapper/Viewport \
            .add_child(level)
    platform_graph_parser = PlatformGraphParser.new()
    level.add_child(platform_graph_parser)
    Gs.profiler.stop("initialize")
    _on_stage_progress("initialize")
    defer("_parse_next")


func _parse_next() -> void:
    Gs.profiler.start("parse")
    platform_graph_parser.connect(
            "calculation_progressed",
            self,
            "_on_graph_parse_progress")
    platform_graph_parser.connect(
            "parse_finished",
            self,
            "_on_calculation_finished")
    platform_graph_parser.parse(
            level_id,
            Surfacer.is_debug_only_platform_graph_state_included,
            true)


func _on_calculation_finished() -> void:
    Gs.profiler.stop("parse")
    _on_stage_progress("parse")
    defer("_save_next")


func _save_next() -> void:
    Gs.profiler.start("save")
    platform_graph_parser.save_platform_graphs()
    Gs.profiler.stop("save")
    _on_stage_progress("save")
    defer("_clean_up_next")


func _clean_up_next() -> void:
    Gs.profiler.start("clean_up")
    platform_graph_parser.queue_free()
    level.queue_free()
    Gs.profiler.stop("clean_up")
    
    var finished: bool = precompute_level_index == \
            Surfacer.precompute_platform_graph_for_levels.size() - 1
    _on_stage_progress("clean_up", finished)
    
    precompute_level_index += 1
    if finished:
        defer("_on_finished")
    else:
        defer("_initialize_next")


func defer(method: String) -> void:
    Gs.time.set_timeout(funcref(self, method), 0.01)


func _on_graph_parse_progress(
        player_index: int,
        player_count: int,
        origin_surface_index: int,
        surface_count: int) -> void:
    var current_graph_calculation_progress_ratio := \
            origin_surface_index / float(surface_count)
    var current_level_calculation_progress_ratio := \
            (player_index + current_graph_calculation_progress_ratio) / \
            float(player_count)
    var sub_step_progress: float = \
            (INITIALIZE_SUB_STEP_PROGRESS_RATIO + \
            current_level_calculation_progress_ratio * \
                    PARSE_SUB_STEP_PROGRESS_RATIO) / \
            PROGRESS_RATIO_TOTAL
    
    var progress: float = \
            (precompute_level_index + sub_step_progress) / \
            Surfacer.precompute_platform_graph_for_levels.size() * \
            100.0
    
    var player_name: String = Gs.level_config.get_level_config(level_id) \
            .platform_graph_player_names[player_index]
    var label_1 := "Level %s (%s of %s)" % [
        Surfacer.precompute_platform_graph_for_levels[ \
                precompute_level_index],
        precompute_level_index + 1,
        Surfacer.precompute_platform_graph_for_levels.size(),
    ]
    var label_2 := "Parsing"
    var label_3 := "Player %s (%s of %s)" % [
        player_name,
        player_index + 1,
        player_count,
    ]
    var label_4 := "Out-bound surface %s of %s" % [
        origin_surface_index + 1,
        surface_count,
    ]
    
    _set_progress(progress, label_1, label_2, label_3, label_4)


func _on_stage_progress(
        step: String,
        finished := false) -> void:
    var sub_step_progress: float
    match step:
        "initialize":
            sub_step_progress = \
                    INITIALIZE_SUB_STEP_PROGRESS_RATIO / \
                    PROGRESS_RATIO_TOTAL
        "parse":
            sub_step_progress = \
                    (INITIALIZE_SUB_STEP_PROGRESS_RATIO + \
                    PARSE_SUB_STEP_PROGRESS_RATIO) / \
                    PROGRESS_RATIO_TOTAL
        "save":
            sub_step_progress = \
                    (INITIALIZE_SUB_STEP_PROGRESS_RATIO + \
                    PARSE_SUB_STEP_PROGRESS_RATIO + \
                    SAVE_SUB_STEP_PROGRESS_RATIO) / \
                    PROGRESS_RATIO_TOTAL
        "clean_up":
            sub_step_progress = \
                    (INITIALIZE_SUB_STEP_PROGRESS_RATIO + \
                    PARSE_SUB_STEP_PROGRESS_RATIO + \
                    SAVE_SUB_STEP_PROGRESS_RATIO + \
                    CLEAN_UP_SUB_STEP_PROGRESS_RATIO) / \
                    PROGRESS_RATIO_TOTAL
        _:
            Utils.error()
    
    var progress: float = \
            (precompute_level_index + sub_step_progress) / \
            Surfacer.precompute_platform_graph_for_levels.size() * \
            100.0
    
    var label_1: String
    var label_2: String
    if finished:
        label_1 = "Done processing all levels."
        label_2 = ""
    else:
        var next_step_label: String = {
            "initialize": "Parsing",
            "parse": "Saving",
            "save": "Cleaning up",
            "clean_up": "Initializing",
        }[step]
        
        label_1 = "Level %s (%s of %s)" % [
            Surfacer.precompute_platform_graph_for_levels[ \
                    precompute_level_index],
            precompute_level_index + 1,
            Surfacer.precompute_platform_graph_for_levels.size(),
        ]
        label_2 = next_step_label
    
    _set_progress(progress, label_1, label_2)


func _set_progress(
        progress: float,
        label_1: String,
        label_2: String,
        label_3 := "",
        label_4 := "") -> void:
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/ProgressBar.value = round(progress)
    
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Labels/Label1.text = label_1
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Labels/Label2.text = label_2
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Labels/Label3.text = label_3
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Labels/Label4.text = label_4
    
    Gs.logger.print("Precompute progress: %s | %s | %s | %s" % \
            [label_1, label_2, label_3, label_4])
    
    _update_metrics()


func _update_metrics() -> void:
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Metrics/DurationLabel.text = \
            Gs.utils.get_time_string_from_seconds( \
                    Gs.time.get_clock_time() - start_time, \
                    false, \
                    false, \
                    true)
    
    for stage in STAGES_TO_DISPLAY_METRICS_FOR:
        stage_to_metric_items[stage][1].text = \
                Gs.utils.get_time_string_from_seconds( \
                        Gs.profiler.get_sum(stage) / 1000.0, \
                        true, \
                        false, \
                        false)
        stage_to_metric_items[stage][1].update_item()
        stage_to_metric_items[stage][2].text = \
                Gs.utils.get_time_string_from_seconds( \
                        Gs.profiler.get_mean(stage) / 1000.0, \
                        true, \
                        false, \
                        false)
        stage_to_metric_items[stage][2].update_item()
        stage_to_metric_items[stage][3].text = \
                Gs.utils.get_time_string_from_seconds( \
                        Gs.profiler.get_min(stage) / 1000.0, \
                        true, \
                        false, \
                        false)
        stage_to_metric_items[stage][3].update_item()
        stage_to_metric_items[stage][4].text = \
                Gs.utils.get_time_string_from_seconds( \
                        Gs.profiler.get_max(stage) / 1000.0, \
                        true, \
                        false, \
                        false)
        stage_to_metric_items[stage][4].update_item()


func _on_finished() -> void:
    Gs.audio.play_sound("achievement")
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/OpenFolderButton \
            .visible = true


func _get_focused_button() -> ScaffolderButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/CloseButton as \
            ScaffolderButton


func _on_OpenFolderButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    var path := PlatformGraphParser.get_os_directory_path()
    Gs.logger.print("Opening platform-graph folder: " + path)
    OS.shell_open(path)


func _on_CloseButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    Gs.time.set_timeout(funcref(Gs.nav, "close_app"), 0.4)
