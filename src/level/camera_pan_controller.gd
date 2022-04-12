class_name CameraPanController
extends Node2D


const _PAN_AND_ZOOM_INTERVAL := 0.05
const _TWEEN_DURATION := 0.1

var _interval_id := -1
var _tween: ScaffolderTween

var _delta_offset := Vector2.INF
var _delta_zoom_multiplier := INF

var _target_offset := Vector2.ZERO
var _target_zoom_multiplier := 1.0

var _tween_offset := Vector2.ZERO
var _tween_zoom_multiplier := 1.0


func _init(previous_pan_controller: CameraPanController = null) -> void:
    _tween = ScaffolderTween.new()
    add_child(_tween)
    if is_instance_valid(previous_pan_controller):
        sync_to_pan_controller(previous_pan_controller)


func sync_to_pan_controller(
        previous_pan_controller: CameraPanController) -> void:
    self._tween_offset = previous_pan_controller._tween_offset
    self._tween_zoom_multiplier = previous_pan_controller._tween_zoom_multiplier
    _update_camera(
            previous_pan_controller._target_offset,
            previous_pan_controller._target_zoom_multiplier)


func _destroy() -> void:
    Sc.time.clear_interval(_interval_id)


func _validate() -> void:
    Sc.logger.error("Abstract CameraPanController._validate is not implemented")


func _update() -> void:
    if _interval_id < 0:
        _interval_id = Sc.time.set_interval(
                funcref(self, "_update_camera_from_deltas"),
                _PAN_AND_ZOOM_INTERVAL)


func _update_camera_from_deltas() -> void:
    assert(_delta_offset != Vector2.INF)
    assert(!is_inf(_delta_zoom_multiplier))
    
    # Calculate the next values.
    var next_offset := _target_offset + _delta_offset
    var next_zoom_multiplier := \
            _target_zoom_multiplier + _delta_zoom_multiplier if \
            Sc.camera.snaps_camera_back_to_character else \
            1.0
    
    # Don't let the pan and zoom exceed their max bounds.
    next_offset.x = clamp(
            next_offset.x,
            -Sc.camera.max_pan_distance_from_pointer,
            Sc.camera.max_pan_distance_from_pointer)
    next_offset.y = clamp(
            next_offset.y,
            -Sc.camera.max_pan_distance_from_pointer,
            Sc.camera.max_pan_distance_from_pointer)
    next_zoom_multiplier = clamp(
            next_zoom_multiplier,
            1.0,
            Sc.camera.max_zoom_multiplier_from_pointer)
    
    _update_camera(next_offset, next_zoom_multiplier)


func reset() -> void:
    _update_camera(Vector2.ZERO, 1.0)


func _update_camera(
        next_offset: Vector2,
        next_zoom_multiplier: float) -> void:
    _target_offset = next_offset
    _target_zoom_multiplier = next_zoom_multiplier
    
    _tween.stop_all()
    
    if Sc.geometry.are_points_equal_with_epsilon(
                _tween_offset, next_offset) and \
            Sc.geometry.are_floats_equal_with_epsilon(
                _tween_zoom_multiplier, next_zoom_multiplier):
        return
    
    # Transition to the new values.
    _tween.interpolate_method(
            self,
            "_update_pan",
            _tween_offset,
            next_offset,
            _TWEEN_DURATION,
            "linear",
            0.0,
            TimeType.PLAY_PHYSICS)
    _tween.interpolate_method(
            self,
            "_update_zoom",
            _tween_zoom_multiplier,
            next_zoom_multiplier,
            _TWEEN_DURATION,
            "linear",
            0.0,
            TimeType.PLAY_PHYSICS)
    _tween.start()


func _update_pan(offset: Vector2) -> void:
    var delta := offset - self._tween_offset
    self._tween_offset = offset
    Sc.camera.controller.set_camera_pan_controller_offset(
            Sc.camera.controller._camera_pan_controller_offset + delta)


func _update_zoom(zoom_multiplier: float) -> void:
    var delta := zoom_multiplier - self._tween_zoom_multiplier
    self._tween_zoom_multiplier = zoom_multiplier
    Sc.camera.controller.set_camera_pan_controller_zoom(
            Sc.camera.controller._camera_pan_controller_zoom + delta)
