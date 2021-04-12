class_name PrecomputePlatformGraphsScreen
extends Screen

const NAME := "precompute_platform_graphs"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

const INITIALIZE_SUB_STEP_PROGRESS_RATIO := 1.0
const PARSE_SUB_STEP_PROGRESS_RATIO := 1.0
const SAVE_SUB_STEP_PROGRESS_RATIO := 1.0
const CLEAN_UP_SUB_STEP_PROGRESS_RATIO := 1.0
const PROGRESS_RATIO_TOTAL := \
        INITIALIZE_SUB_STEP_PROGRESS_RATIO + \
        PARSE_SUB_STEP_PROGRESS_RATIO + \
        SAVE_SUB_STEP_PROGRESS_RATIO + \
        CLEAN_UP_SUB_STEP_PROGRESS_RATIO

var go_icon_scale_multiplier := 1.0

var projected_image: Control

func _init().( \
        NAME, \
        LAYER_NAME, \
        AUTO_ADAPTS_GUI_SCALE, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
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
    # - Load/parse level and graph.
    # - Encode graph to a string.
    # - Save to a file.
    # - Add logic in SurfacerLevel to check for a corresponding graph file.
    #   - Have the level still support conditionally parsing the graph
    #     on-demand if needed.
    # - Add logic to decode the graph string into a graph for the level.
    # - Add logic to validate the graph.
    #   - Parse the active TileMaps dynamically with a new SurfaceParser.
    #   - Check that the surfaces of the graph match those of the SurfaceParser.
    #   - Bypass this validation when not in debug or playtest.
    # - Refactor the platform graph parsing a little:
    #   - if !Surfacer.uses_threads_for_platform_graph_calculation
    #   - Between every iteration of the graph-calculation for-loop, call the
    #     next iteration via call_deferred.
    #   - Then emit a signal with the current calculation progress.
    #   - Use this signal to update a progress bar.
    # - Add this progress bar to both the precompute screen and the game screen.
    # - Show a success message and a close button when calculating is done.
    #   - Have button be shiny/autofocused within Screen for pressing via enter.
    # - Display a link to open the file location:
    #   - OS.shell_open(get_user_data_dir() + "/" + SurfacerLevel.PLATFORM_GRAPHS_DIRECTORY_NAME)
    # - Add calls to Profiler, and print results within screen (and console).
    #   - Use these results to give some ballpark sub-step ratios for updating
    #     the progress bar.
    # - Also print number of used cells in combined tile maps for the current
    #   level (during computation).
    #   - This should help give some indication that the current level parsing
    #     might take longer.
    pass
    
    precompute_level_index = 0
    call_deferred("_initialize_next")

var precompute_level_index := -1
var level_id: String
var platform_graph_parser: PlatformGraphParser
var level: SurfacerLevel

func _initialize_next() -> void:
    level_id = Surfacer.precompute_platform_graph_for_levels[ \
            precompute_level_index]
    level = Gs.utils.add_scene( \
            null, \
            Gs.level_config.get_level_config(level_id).scene_path, \
            false, \
            true)
    level.id = level_id
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/LevelWrapper/Viewport \
            .add_child(level)
    platform_graph_parser = PlatformGraphParser.new()
    level.add_child(platform_graph_parser)
    _on_progress("initialize")
    call_deferred("_parse_next")

func _parse_next() -> void:
    platform_graph_parser.parse(level_id, true)
    _on_progress("parse")
    call_deferred("_save_next")

func _save_next() -> void:
    platform_graph_parser.save_platform_graphs()
    _on_progress("save")
    call_deferred("_clean_up_next")

func _clean_up_next() -> void:
    platform_graph_parser.queue_free()
    level.queue_free()
    
    var finished := precompute_level_index == \
            Surfacer.precompute_platform_graph_for_levels.size() - 1
    _on_progress("clean_up", finished)
    
    precompute_level_index += 1
    if finished:
        call_deferred("_on_finished")
    else:
        call_deferred("_initialize_next")

func _on_progress(step: String, finished := false) -> void:
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
    
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/ProgressBar.value = round(progress)
    
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
        
        label = "%3d%% - %s level %s - %s of %s" % [
            progress,
            next_step_label,
            Surfacer.precompute_platform_graph_for_levels[ \
                    precompute_level_index],
            precompute_level_index + 1,
            Surfacer.precompute_platform_graph_for_levels.size(),
        ]
    
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Label.text = \
            label
    
    Gs.logger.print("*** Precompute progress ***: " + label)

func _on_finished() -> void:
    # FIXME: -----------------------
    pass

func _on_CloseButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    Gs.time.set_timeout(funcref(self, "_quit"), 0.4)

func _quit() -> void:
    get_tree().quit()
