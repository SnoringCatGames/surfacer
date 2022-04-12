class_name CameraPanController
extends Node2D


const _TWEEN_DURATION := 0.1

var _tween: ScaffolderTween

var _target_offset := Vector2.ZERO
var _target_zoom := 1.0

var _tween_offset := Vector2.ZERO
var _tween_zoom := 1.0


func _init(previous_pan_controller: CameraPanController = null) -> void:
    _tween = ScaffolderTween.new()
    add_child(_tween)
    if is_instance_valid(previous_pan_controller):
        sync_to_pan_controller(previous_pan_controller)


func sync_to_pan_controller(
        previous_pan_controller: CameraPanController) -> void:
    self._tween_offset = previous_pan_controller._tween_offset
    self._tween_zoom = previous_pan_controller._tween_zoom
    _update_camera(
            previous_pan_controller._target_offset,
            previous_pan_controller._target_zoom)


func _destroy() -> void:
    pass


func _validate() -> void:
    Sc.logger.error("Abstract CameraPanController._validate is not implemented")


func reset() -> void:
    _update_camera(Vector2.ZERO, 1.0)


func _update_camera(
        next_offset: Vector2,
        next_zoom: float) -> void:
    var previous_target_offset := _target_offset
    var previous_target_zoom := _target_zoom
    
    _target_offset = next_offset
    _target_zoom = next_zoom
    
    if Sc.geometry.are_points_equal_with_epsilon(
                previous_target_offset, _target_offset) and \
            Sc.geometry.are_floats_equal_with_epsilon(
                previous_target_zoom, _target_zoom):
        return
    
    # Transition to the new values.
    _tween.stop_all()
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
            _tween_zoom,
            next_zoom,
            _TWEEN_DURATION,
            "linear",
            0.0,
            TimeType.PLAY_PHYSICS)
    _tween.start()


func _update_pan(offset: Vector2) -> void:
    self._tween_offset = offset
    Sc.camera.controller.set_camera_pan_controller_offset(offset)


func _update_zoom(zoom: float) -> void:
    self._tween_zoom = zoom
    Sc.camera.controller.set_camera_pan_controller_zoom(zoom)
