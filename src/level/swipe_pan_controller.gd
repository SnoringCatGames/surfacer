class_name SwipePanController
extends CameraPanController


# FIXME: LEFT OFF HERE: --------------------------------------
# - TIE INTO Sc.level.pointer_listener.
#   - I might need to add support for multi-touch to this?
# 
# - Implement touch-based drag pan.
# - Add momentum and friction to drag.
# - Implement multi-touch pinch-zoom.
# - Add momentum and friction to pinch-zoom.
# - Look through NavigationPreselectionDragPanController and make sure all the
#   corresponding state is used and reset in this class too.
# - Update SurfacerLevel, or whereever, to swap-out the correct
#   CameraPanController as needed.
# 
# - Sc.level.surfaces_bounds





func _init(previous_pan_controller: CameraPanController = null).(
        previous_pan_controller) -> void:
    pass


func _validate() -> void:
    # FIXME: LEFT OFF HERE: --------------------------------------
    assert(Sc.gui.is_player_interaction_enabled)


func _unhandled_input(event: InputEvent) -> void:
    # FIXME: LEFT OFF HERE: --------------------------------------
    pass
