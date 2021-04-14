class_name PrecomputePlatformGraphsScreen
extends Screen

const NAME := "precompute_platform_graphs"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

const INITIALIZE_SUB_STEP_PROGRESS_RATIO := 0.05
const PARSE_SUB_STEP_PROGRESS_RATIO := 0.75
const SAVE_SUB_STEP_PROGRESS_RATIO := 0.15
const CLEAN_UP_SUB_STEP_PROGRESS_RATIO := 0.05
const PROGRESS_RATIO_TOTAL := \
        INITIALIZE_SUB_STEP_PROGRESS_RATIO + \
        PARSE_SUB_STEP_PROGRESS_RATIO + \
        SAVE_SUB_STEP_PROGRESS_RATIO + \
        CLEAN_UP_SUB_STEP_PROGRESS_RATIO

var go_icon_scale_multiplier := 1.0

var projected_image: Control

func _init().(
        NAME,
        LAYER_NAME,
        AUTO_ADAPTS_GUI_SCALE,
        INCLUDES_STANDARD_HIERARCHY,
        INCLUDES_NAV_BAR,
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    pass

func _on_activated(previous_screen_name: String) -> void:
    ._on_activated(previous_screen_name) 
    Gs.time.set_timeout(funcref(self, "_compute"), 0.2)

func _compute() -> void:
    assert(Gs.debug)
    assert(Gs.utils.get_is_pc_device())
    assert(Surfacer.is_precomputing_platform_graphs)
    assert(!Surfacer.precompute_platform_graph_for_levels.empty())
    
    Surfacer.is_inspector_enabled = false
    
    # FIXME: ------------------------------------------------------------
    # - Test current updates to defer each iteration in parser and graph.
    # - Refactor the presentation of the progress info.
    # 
    # - LEFT OFF HERE:
    #   - Take a screen recording of scrolling through the current encoding.
    #   - Make a copy of the current encoding. Compare size later.
    # 
    # - Refactor the platform graph parsing a little:
    #   - if !Surfacer.uses_threads_for_platform_graph_calculation
    #   - Between every iteration of the graph-calculation for-loop, call the
    #     next iteration via defer.
    #   - Then emit a signal with the current calculation progress.
    #   - Use this signal to update a progress bar.
    # - Add this progress bar to both the precompute screen and the game screen.
    # - Add calls to Profiler, and print results within screen (and console).
    #   - Use these results to give some ballpark sub-step ratios for updating
    #     the progress bar.
    # - Also print number of used cells in combined tile maps for the current
    #   level (during computation).
    #   - This should help give some indication that the current level parsing
    #     might take longer.
    
    precompute_level_index = 0
    defer("_initialize_next")

var precompute_level_index := -1
var level_id: String
var platform_graph_parser: PlatformGraphParser
var level: SurfacerLevel

func _initialize_next() -> void:
    level_id = Surfacer.precompute_platform_graph_for_levels[ \
            precompute_level_index]
    level = Gs.utils.add_scene(
            null,
            Gs.level_config.get_level_config(level_id).scene_path,
            false,
            true)
    level.id = level_id
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/LevelWrapper/Viewport \
            .add_child(level)
    platform_graph_parser = PlatformGraphParser.new()
    level.add_child(platform_graph_parser)
    _on_stage_progress("initialize")
    defer("_parse_next")

func _parse_next() -> void:
    platform_graph_parser.connect(
            "calculation_progress",
            self,
            "_on_graph_parse_progress")
    platform_graph_parser.connect(
            "parse_finished",
            self,
            "_on_calculation_finished")
    platform_graph_parser.parse(level_id, true)

func _on_calculation_finished() -> void:
    _on_stage_progress("parse")
    defer("_save_next")

func _save_next() -> void:
    platform_graph_parser.save_platform_graphs()
    _on_stage_progress("save")
    defer("_clean_up_next")

func _clean_up_next() -> void:
    platform_graph_parser.queue_free()
    level.queue_free()
    
    var finished := precompute_level_index == \
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
    
    var progress := \
            (precompute_level_index + sub_step_progress) / \
            Surfacer.precompute_platform_graph_for_levels.size() * \
            100.0
    
    var player_name: String = Surfacer.player_params.keys()[player_index]
    var label_1 := "%s level %s (%s of %s)" % [
        "Parsing",
        Surfacer.precompute_platform_graph_for_levels[ \
                precompute_level_index],
        precompute_level_index + 1,
        Surfacer.precompute_platform_graph_for_levels.size(),
    ]
    var label_2 := "Player %s (%s of %s)" % [
        player_name,
        player_index + 1,
        player_count,
    ]
    var label_3 := "Origin surface %s of %s" % [
        origin_surface_index,
        surface_count,
    ]
    
    _set_progress(progress, label_1, label_2, label_3)

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
    
    var progress := \
            (precompute_level_index + sub_step_progress) / \
            Surfacer.precompute_platform_graph_for_levels.size() * \
            100.0
    
    var label: String
    if finished:
        label = "Done processing all levels."
    else:
        var next_step_label: String = {
            "initialize": "Parsing",
            "parse": "Saving",
            "save": "Cleaning up",
            "clean_up": "Initializing",
        }[step]
        
        label = "%s level %s (%s of %s)" % [
            next_step_label,
            Surfacer.precompute_platform_graph_for_levels[ \
                    precompute_level_index],
            precompute_level_index + 1,
            Surfacer.precompute_platform_graph_for_levels.size(),
        ]
    
    _set_progress(progress, label)

func _set_progress(
        progress: float,
        label_1: String,
        label_2 := "",
        label_3 := "") -> void:
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/ProgressBar.value = round(progress)
    
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Label.text = label_1
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Label2.text = label_2
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Label3.text = label_3
    
    Gs.logger.print("Precompute progress: %s | %s | %s" % \
            [label_1, label_2, label_3])

func _on_finished() -> void:
    Gs.audio.play_sound("achievement")
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer/OpenFolderButton \
            .visible = true

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer/CloseButton as \
            ShinyButton

func _on_OpenFolderButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    var path := PlatformGraphParser.get_directory_path()
    Gs.logger.print("Opening platform-graph folder: " + path)
    OS.shell_open(path)

func _on_CloseButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    Gs.time.set_timeout(funcref(Gs.nav, "close_app"), 0.4)
