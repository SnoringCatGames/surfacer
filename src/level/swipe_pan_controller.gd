class_name SwipePanController
extends CameraPanController


# FIXME: LEFT OFF HERE: --------------------------------------
# 
# - Implement zoom/pan boundaries, and standardize with other controller.
#   - Sc.level.level_bounds
# 
# - Add momentum and friction to drag.
# - Add momentum and friction to pinch-zoom.


const _PAN_SPEED_MULTIPLIER := 1.5
const _ZOOM_SPEED_MULTIPLIER := 1.8

var _drag_start_position := Vector2.INF
var _zoom_start_distance := INF


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


func _reset() -> void:
    self._drag_start_position = Vector2.INF
    self._zoom_start_distance = INF


func _on_dragged(
        pointer_screen_position: Vector2,
        pointer_level_position: Vector2) -> void:
    if Sc.level.pointer_listener.get_is_control_pressed():
        _reset()
        return
    var offset: Vector2 = \
            _target_offset - \
            Sc.level.pointer_listener.current_drag_screen_displacement * \
            _PAN_SPEED_MULTIPLIER * \
            Sc.camera.controller.get_zoom()
    _update_camera(offset, _target_zoom)


func _on_released(
        pointer_screen_position: Vector2,
        pointer_level_position: Vector2) -> void:
    if Sc.level.pointer_listener.get_is_control_pressed():
        _reset()
        return
    _reset()


func _on_pinch_changed(
        pinch_distance: float,
        pinch_angle: float) -> void:
    var distance_ratio := \
            Sc.level.pointer_listener.current_pinch_distance_ratio_from_previous
    if distance_ratio > 1.0:
        distance_ratio = 1.0 + (distance_ratio - 1.0) * _ZOOM_SPEED_MULTIPLIER
    else:
        distance_ratio = 1.0 - (1.0 - distance_ratio) * _ZOOM_SPEED_MULTIPLIER
    var zoom: float = _target_zoom / distance_ratio
    _update_camera(_target_offset, zoom)


func _on_pinch_finished() -> void:
    _reset()
