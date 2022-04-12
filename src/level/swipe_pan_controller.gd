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
    Sc.level.pointer_listener \
            .connect("dragged", self, "_on_dragged")
    Sc.level.pointer_listener \
            .connect("released", self, "_on_released")
    Sc.level.pointer_listener \
            .connect("pinch_changed", self, "_on_pinch_changed")
    Sc.level.pointer_listener \
            .connect("pinch_finished", self, "_on_pinch_finished")


func _validate() -> void:
    # FIXME: LEFT OFF HERE: --------------------------------------
    assert(Sc.gui.is_player_interaction_enabled)


func _on_dragged(pointer_position: Vector2) -> void:
    if Sc.level.pointer_listener.get_is_control_pressed():
        return
    # FIXME: LEFT OFF HERE: --------------------------------------
    pass


func _on_released(pointer_position: Vector2) -> void:
    if Sc.level.pointer_listener.get_is_control_pressed():
        return
    # FIXME: LEFT OFF HERE: --------------------------------------
    pass


func _on_pinch_changed(pinch_distance: float, pinch_angle: float) -> void:
    # FIXME: LEFT OFF HERE: --------------------------------------
    pass


func _on_pinch_finished() -> void:
    # FIXME: LEFT OFF HERE: --------------------------------------
    pass
