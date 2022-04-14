class_name SwipePanController
extends CameraPanController


const _PAN_SPEED_MULTIPLIER := 1.5
const _PINCH_ZOOM_SPEED_MULTIPLIER := 1.0

const _MAX_PAN_SPEED := 10000.0


const _PAN_CONTINUATION_DECELERATION := -6000.0
const _ZOOM_CONTINUATION_DECELERATION := -6000.0
const _PAN_CONTINUATION_MIN_SPEED := 0.2
const _ZOOM_CONTINUATION_MIN_SPEED := 0.001

var _is_pan_continuation_active := false
var _is_zoom_continuation_active := false
var _pan_velocity := Vector2.ZERO
var _zoom_speed := 0.0
var _zoom_target_level_position := Vector2.INF


func _init(previous_pan_controller: CameraPanController = null).(
        previous_pan_controller) -> void:
    Sc.level.pointer_listener.connect(
            "single_touch_dragged", self, "_on_single_touch_dragged")
    Sc.level.pointer_listener.connect(
            "single_touch_released", self, "_on_single_touch_released")
    Sc.level.pointer_listener.connect(
            "pinch_changed", self, "_on_pinch_changed")
    Sc.level.pointer_listener.connect(
            "pinch_first_touch_released",
            self,
            "_on_pinch_first_touch_released")


func _validate() -> void:
    # FIXME: LEFT OFF HERE: --------------------------------------
    assert(Sc.gui.is_player_interaction_enabled)


func _physics_process(physics_play_time_delta: float) -> void:
    _update_pan_continuation(physics_play_time_delta)
    _update_zoom_continuation(physics_play_time_delta)


func _update_pan_continuation(physics_play_time_delta: float) -> void:
    if !_is_pan_continuation_active:
        return
    
    if Sc.level.pointer_listener.is_touch_active:
        # Stopped by a touch.
        _pan_velocity = Vector2.ZERO
        _is_pan_continuation_active = false
        return
    
    if _pan_velocity == Vector2.ZERO:
        # TODO: This shouldn't be possible, but is happening in practice.
        _pan_velocity = Vector2.ZERO
        _is_pan_continuation_active = false
        return
    
    assert(_pan_velocity != Vector2.ZERO and \
            _pan_velocity != Vector2.INF and \
            !is_nan(_pan_velocity.x))
    
    var pan_direction := _pan_velocity.normalized()
    
    var min_velocity_x: float
    var min_velocity_y: float
    var max_velocity_x: float
    var max_velocity_y: float
    if _pan_velocity.x < 0:
        min_velocity_x = _pan_velocity.x
        max_velocity_x = 0.0
    else:
        min_velocity_x = 0.0
        max_velocity_x = _pan_velocity.x
    if _pan_velocity.y < 0:
        min_velocity_y = _pan_velocity.y
        max_velocity_y = 0.0
    else:
        min_velocity_y = 0.0
        max_velocity_y = _pan_velocity.y
    
    var deceleration := \
            _PAN_CONTINUATION_DECELERATION * Sc.camera.controller.get_zoom()
    
    _pan_velocity += pan_direction * deceleration * physics_play_time_delta
    
    _pan_velocity.x = clamp(_pan_velocity.x, min_velocity_x, max_velocity_x)
    _pan_velocity.y = clamp(_pan_velocity.y, min_velocity_y, max_velocity_y)
    
    assert(_pan_velocity != Vector2.INF and \
            !is_nan(_pan_velocity.x))
    
    if _pan_velocity.length_squared() < \
            _PAN_CONTINUATION_MIN_SPEED * _PAN_CONTINUATION_MIN_SPEED:
        # Slowed to a stop.
        _pan_velocity = Vector2.ZERO
        _is_pan_continuation_active = false
        return
    
    var delta_offset := \
            _pan_velocity * physics_play_time_delta * \
            _PAN_SPEED_MULTIPLIER
    var offset := _target_offset + delta_offset
    
    _update_camera(offset, _target_zoom, false)


func _update_zoom_continuation(physics_play_time_delta: float) -> void:
    if !_is_zoom_continuation_active:
        return
    
    if Sc.level.pointer_listener.is_multi_touch_active:
        # Stopped by a touch.
        _zoom_speed = 0.0
        _zoom_target_level_position = Vector2.INF
        _is_zoom_continuation_active = false
        return
    
    assert(_zoom_speed != 0.0 and !is_inf(_zoom_speed))
    
    var deceleration := \
            _ZOOM_CONTINUATION_DECELERATION if \
            _zoom_speed > 0.0 else \
            -_ZOOM_CONTINUATION_DECELERATION
    _zoom_speed += deceleration * physics_play_time_delta
    
    if abs(_zoom_speed) < _ZOOM_CONTINUATION_MIN_SPEED:
        # Slowed to a stop.
        _zoom_speed = 0.0
        _zoom_target_level_position = Vector2.INF
        _is_zoom_continuation_active = false
        return
    
    var zoom_speed_distance_ratio := 1.0 + _zoom_speed
    if zoom_speed_distance_ratio > 1.0:
        zoom_speed_distance_ratio = \
                1.0 + (zoom_speed_distance_ratio - 1.0) * _PINCH_ZOOM_SPEED_MULTIPLIER
    else:
        zoom_speed_distance_ratio = \
                1.0 - (1.0 - zoom_speed_distance_ratio) * _PINCH_ZOOM_SPEED_MULTIPLIER
    var zoom: float = _target_zoom / zoom_speed_distance_ratio
    
    _zoom_to_position(zoom, _zoom_target_level_position, false)


func _start_pan_continuation() -> void:
    if _is_pan_continuation_active:
        return
    if _pan_velocity == Vector2.ZERO:
        return
    _is_pan_continuation_active = true


func _start_zoom_continuation() -> void:
    if _is_zoom_continuation_active:
        return
    if _zoom_speed == 0.0:
        return
    _is_zoom_continuation_active = true


func _on_single_touch_dragged(
        pointer_screen_position: Vector2,
        pointer_level_position: Vector2) -> void:
    if Sc.level.pointer_listener.get_is_control_pressed():
        return
    self._pan_velocity = Sc.geometry.clamp_vector_length(
            Sc.level.pointer_listener.current_drag_level_velocity,
            0.0,
            _MAX_PAN_SPEED)
    var offset: Vector2 = \
            _target_offset - \
            Sc.level.pointer_listener.current_drag_screen_displacement * \
            _PAN_SPEED_MULTIPLIER * \
            Sc.camera.controller.get_zoom()
    _update_camera(offset, _target_zoom, false)


func _on_single_touch_released(
        pointer_screen_position: Vector2,
        pointer_level_position: Vector2) -> void:
    if Sc.level.pointer_listener.get_is_control_pressed():
        return
    _start_pan_continuation()


func _on_pinch_changed(
        pinch_distance: float,
        pinch_angle: float) -> void:
    self._zoom_target_level_position = \
            Sc.level.pointer_listener.current_pinch_center_level_position
    self._zoom_speed = \
            Sc.level.pointer_listener.current_pinch_screen_distance_speed / \
            Sc.level.pointer_listener.current_pinch_screen_distance
    
    var distance_ratio := \
            Sc.level.pointer_listener.current_pinch_screen_distance_ratio_from_previous
    var foo := distance_ratio
    if distance_ratio > 1.0:
        distance_ratio = 1.0 + (distance_ratio - 1.0) * _PINCH_ZOOM_SPEED_MULTIPLIER
    else:
        distance_ratio = 1.0 - (1.0 - distance_ratio) * _PINCH_ZOOM_SPEED_MULTIPLIER
    var zoom: float = _target_zoom / distance_ratio
    
    _zoom_to_position(zoom, _zoom_target_level_position, false)


func _on_pinch_first_touch_released() -> void:
    _start_zoom_continuation()


func _get_camera_parent_position() -> Vector2:
    return Vector2.ZERO
