class_name PrecomputePlatformGraphsScreen
extends Screen

const NAME := "precompute_platform_graphs"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

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
    
    assert(Surfacer.is_precomputing_platform_graphs)
    assert(!Surfacer.precompute_platform_graph_for_levels.empty())
    
    # FIXME: ------------------------------------------------------------
    # - Load/parse level and graph.
    # - Encode graph to a string.
    # - Save to a file.
    # - Add logic in SurfacerLevel to check for a corresponding graph file.
    # - Add logic to decode the graph string into a graph for the level.
    # - Refactor the platform graph parsing a little:
    #   - if !Surfacer.uses_threads_for_platform_graph_calculation
    #   - Between every iteration of the graph-calculation for-loop, call the
    #     next iteration via call_deferred.
    #   - Then emit a signal with the current calculation progress.
    #   - Use this signal to update a porgress bar.
    # - Show a success message and a close button when calculating is done.
    #   - Have button be shiny/autofocused within Screen for pressing via enter.
    pass
    
    for level_id in Surfacer.precompute_platform_graph_for_levels:
        pass

func _on_CloseButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.time.set_timeout(funcref(self, "_quit"), 0.4)

func _quit() -> void:
    get_tree().quit()
