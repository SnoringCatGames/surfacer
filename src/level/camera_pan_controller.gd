class_name CameraPanController
extends Node2D


const _TWEEN_DURATION := 0.1
const _MIN_CAMERA_ZOOM := 0.01

const _SCROLL_ZOOM_SPEED_MULTIPLIER := 1.08

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


func _unhandled_input(event: InputEvent) -> void:
    # Mouse wheel events are never considered pressed by Godot--rather they are
    # only ever considered to have just happened.
    if Sc.gui.is_player_interaction_enabled and \
            event is InputEventMouseButton:
        if event.button_index == BUTTON_WHEEL_UP or \
                event.button_index == BUTTON_WHEEL_DOWN:
            # Zoom toward the cursor.
            var zoom := \
                    _target_zoom / _SCROLL_ZOOM_SPEED_MULTIPLIER if \
                    event.button_index == BUTTON_WHEEL_UP else \
                    _target_zoom * _SCROLL_ZOOM_SPEED_MULTIPLIER
            var cursor_level_position: Vector2 = \
                    Sc.utils.get_level_touch_position(event)
            _zoom_to_position(zoom, cursor_level_position)


func _zoom_to_position(
        zoom: float,
        zoom_target_level_position: Vector2,
        includes_tween := true) -> void:
    var camera_level_position: Vector2 = \
            _get_camera_parent_position() + Sc.camera.controller.offset
    var cursor_camera_position := \
            zoom_target_level_position - camera_level_position
    var delta_offset := \
            cursor_camera_position * (1 - zoom / _target_zoom)
    var offset := _target_offset + delta_offset
    _update_camera(offset, zoom, includes_tween)


func _update_camera(
        next_offset: Vector2,
        next_zoom: float,
        includes_tween := true) -> void:
    var previous_target_offset := _target_offset
    var previous_target_zoom := _target_zoom
    
    # Ensure the pan-controller keeps the camera in-bounds.
    var other_zoom_factor: float = \
            Sc.camera.controller.get_zoom() / \
            Sc.camera.controller._manual_zoom / \
            Sc.camera.controller._camera_pan_controller_zoom
    next_zoom = clamp(
            next_zoom,
            _MIN_CAMERA_ZOOM / other_zoom_factor,
            _max_zoom_for_camera_bounds / other_zoom_factor)
    var accountable_camera_zoom := next_zoom * other_zoom_factor
    var camera_position_without_pan_controller: Vector2 = \
            _get_camera_parent_position() + \
            Sc.camera.controller.offset - \
            Sc.camera.controller._manual_offset - \
            Sc.camera.controller._camera_pan_controller_offset
    var min_offset := \
            _calculate_min_position_for_zoom_for_camera_bounds(
                accountable_camera_zoom) - \
            camera_position_without_pan_controller
    var max_offset := \
            _calculate_max_position_for_zoom_for_camera_bounds(
                accountable_camera_zoom) - \
            camera_position_without_pan_controller
    next_offset.x = clamp(next_offset.x, min_offset.x, max_offset.x)
    next_offset.y = clamp(next_offset.y, min_offset.y, max_offset.y)
    
    _target_offset = next_offset
    _target_zoom = next_zoom
    
    if !includes_tween:
        _tween.stop_all()
        _update_pan(_target_offset)
        _update_zoom(_target_zoom)
    else:
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
