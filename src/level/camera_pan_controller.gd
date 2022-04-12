class_name CameraPanController
extends Node2D


const _TWEEN_DURATION := 0.1
const _MIN_CAMERA_ZOOM := 0.00001

var _tween: ScaffolderTween

var _target_offset := Vector2.ZERO
var _target_zoom := 1.0

var _tween_offset := Vector2.ZERO
var _tween_zoom := 1.0

var _max_zoom_for_camera_bounds: float


func _init(previous_pan_controller: CameraPanController = null) -> void:
    _tween = ScaffolderTween.new()
    add_child(_tween)
    if is_instance_valid(previous_pan_controller):
        sync_to_pan_controller(previous_pan_controller)
    _max_zoom_for_camera_bounds = _calculate_max_zoom_for_camera_bounds()


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
    
    # Ensure the pan-controller keeps the camera in-bounds.
    next_zoom = clamp(next_zoom, _MIN_CAMERA_ZOOM, _max_zoom_for_camera_bounds)
    var camera_position_without_pan_controller: Vector2 = \
            _get_camera_parent_position() + \
            Sc.camera.controller.offset - \
            Sc.camera.controller._camera_pan_controller_offset
    var min_offset := \
            _calculate_min_position_for_zoom_for_camera_bounds(next_zoom) - \
            camera_position_without_pan_controller
    var max_offset := \
            _calculate_max_position_for_zoom_for_camera_bounds(next_zoom) - \
            camera_position_without_pan_controller
    next_offset.x = clamp(next_offset.x, min_offset.x, max_offset.x)
    next_offset.y = clamp(next_offset.y, min_offset.y, max_offset.y)
    
    # FIXME: --------------------
#    Sc.logger.print(">>>>>>>>>>>>>>>>>>>>>")
#    Sc.logger.print(str(Sc.level.camera_bounds))
#    Sc.logger.print(str(Sc.camera.controller.get_camera().get_viewport_rect().size * next_zoom))
#    Sc.logger.print(str(Sc.camera.controller.get_visible_region()))
#    Sc.logger.print("%s, %s, %s, %s" % [str(next_zoom), str(next_offset), str(min_offset), str(max_offset)])
    
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


func _get_camera_parent_position() -> Vector2:
    Sc.logger.error(
            "Abstract CameraPanController._get_camera_parent_position is " +
            "not implemented")
    return Vector2.INF


func _calculate_max_zoom_for_camera_bounds() -> float:
    var viewport_size: Vector2 = \
            Sc.camera.controller.get_camera().get_viewport_rect().size
    var viewport_aspect_ratio := viewport_size.x / viewport_size.y
    var camera_bounds_size: Vector2 = Sc.level.camera_bounds.size
    var camera_bounds_aspect_ratio := \
            camera_bounds_size.x / camera_bounds_size.y
    if viewport_aspect_ratio > camera_bounds_aspect_ratio:
        # Limited by x dimension.
        return camera_bounds_size.x / viewport_size.x
    else:
        # Limited by y dimension.
        return camera_bounds_size.y / viewport_size.y


func _calculate_min_position_for_zoom_for_camera_bounds(zoom: float) -> Vector2:
    var camera_region_size: Vector2 = \
            Sc.camera.controller.get_camera().get_viewport_rect().size * zoom
    return Sc.level.camera_bounds.position + camera_region_size / 2.0


func _calculate_max_position_for_zoom_for_camera_bounds(zoom: float) -> Vector2:
    var camera_region_size: Vector2 = \
            Sc.camera.controller.get_camera().get_viewport_rect().size * zoom
    return Sc.level.camera_bounds.end - camera_region_size / 2.0
