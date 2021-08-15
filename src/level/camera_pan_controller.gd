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


func _init() -> void:
    _tween = ScaffolderTween.new()
    add_child(_tween)


func _destroy() -> void:
    Sc.time.clear_interval(_interval_id)


func _unhandled_input(event: InputEvent) -> void:
    if !Sc.gui.is_player_interaction_enabled:
        return
    
    var is_control_pressed: bool = \
            Sc.level_button_input.is_key_pressed(KEY_CONTROL) or \
            Sc.level_button_input.is_key_pressed(KEY_META)
    
    if is_control_pressed:
        _stop_drag()
    
    # Touch-up: Position selection.
    if event is InputEventScreenTouch and \
            !event.pressed:
        _stop_drag()
    
    var pointer_drag_position := Vector2.INF
    
    # Touch-down: Position pre-selection.
    if event is InputEventScreenTouch and \
            event.pressed:
        pointer_drag_position = Sc.utils.get_level_touch_position(event)
    
    # Touch-move: Position pre-selection.
    if event is InputEventScreenDrag:
        pointer_drag_position = Sc.utils.get_level_touch_position(event)
    
    if pointer_drag_position != Vector2.INF:
        _update_drag(pointer_drag_position)


func _validate() -> void:
    assert(Su.max_zoom_multiplier_from_pointer >= 1.0)
    assert(Su.max_pan_distance_from_pointer >= 0.0)
    assert(Su.screen_size_ratio_distance_from_edge_to_start_pan_from_pointer <= \
            0.5 and \
            Su.screen_size_ratio_distance_from_edge_to_start_pan_from_pointer > \
            0.0)


func _stop_drag() -> void:
    Sc.time.clear_interval(_interval_id)
    _interval_id = -1
    
    _delta_offset = Vector2.INF
    _delta_zoom_multiplier = INF
    
    if Su.snaps_camera_back_to_character:
        _update_camera(Vector2.ZERO, 1.0)


func _update_drag(pointer_position: Vector2) -> void:
    _update_pan_and_zoom_delta_from_pointer(pointer_position)
    if _interval_id < 0:
        _interval_id = Sc.time.set_interval(
                funcref(self, "_update_camera_from_deltas"),
                _PAN_AND_ZOOM_INTERVAL)


func _update_pan_and_zoom_delta_from_pointer(
        pointer_position: Vector2) -> void:
    # Calculate the camera bounds and the region that controls pan and zoom.
    var pointer_max_control_bounds: Rect2 = Sc.camera_controller.get_bounds()
    var camera_center := \
            pointer_max_control_bounds.position + \
            pointer_max_control_bounds.size / 2.0
    var min_control_bounds_size: Vector2 = \
            pointer_max_control_bounds.size * \
            (1 - \
            Su.screen_size_ratio_distance_from_edge_to_start_pan_from_pointer * 2)
    var min_control_bounds_position: Vector2 = \
            pointer_max_control_bounds.position + \
            pointer_max_control_bounds.size * \
            Su.screen_size_ratio_distance_from_edge_to_start_pan_from_pointer
    var pointer_min_control_bounds := Rect2(
            min_control_bounds_position,
            min_control_bounds_size)
    
    # Calculate drag control weights according to the pointer position.
    var pan_zoom_control_weight_x: float
    if pointer_position.x < camera_center.x:
        pointer_position.x = max(
                pointer_position.x,
                pointer_max_control_bounds.position.x)
        if pointer_position.x < pointer_min_control_bounds.position.x:
            # Dragging left.
            pan_zoom_control_weight_x = \
                    -1 * \
                    (pointer_min_control_bounds.position.x - \
                            pointer_position.x) / \
                    (pointer_min_control_bounds.position.x - \
                            pointer_max_control_bounds.position.x)
    else:
        pointer_position.x = min(
                pointer_position.x,
                pointer_max_control_bounds.end.x)
        if pointer_position.x > pointer_min_control_bounds.end.x:
            # Dragging right.
            pan_zoom_control_weight_x = \
                    (pointer_position.x - \
                            pointer_min_control_bounds.end.x) / \
                    (pointer_max_control_bounds.end.x - \
                            pointer_min_control_bounds.end.x)
    var pan_zoom_control_weight_y: float
    if pointer_position.y < camera_center.y:
        pointer_position.y = max(
                pointer_position.y,
                pointer_max_control_bounds.position.y)
        if pointer_position.y < pointer_min_control_bounds.position.y:
            # Dragging up.
            pan_zoom_control_weight_y = \
                    -1 * \
                    (pointer_min_control_bounds.position.y - \
                            pointer_position.y) / \
                    (pointer_min_control_bounds.position.y - \
                            pointer_max_control_bounds.position.y)
    else:
        pointer_position.y = min(
                pointer_position.y,
                pointer_max_control_bounds.end.y)
        if pointer_position.y > pointer_min_control_bounds.end.y:
            # Dragging down.
            pan_zoom_control_weight_y = \
                    (pointer_position.y - \
                            pointer_min_control_bounds.end.y) / \
                    (pointer_max_control_bounds.end.y - \
                            pointer_min_control_bounds.end.y)
    
    # Calcute the pan and zoom deltas for the current frame and drag weight.
    var per_frame_pan_ratio: float = \
            _PAN_AND_ZOOM_INTERVAL / \
            Su.duration_to_max_pan_from_pointer_at_max_control
    var per_frame_zoom_ratio: float = \
            _PAN_AND_ZOOM_INTERVAL / \
            Su.duration_to_max_zoom_from_pointer_at_max_control
    var max_pan_distance_per_frame: float = \
            Su.max_pan_distance_from_pointer * per_frame_pan_ratio
    var max_zoom_delta_per_frame: float = \
            Su.max_zoom_multiplier_from_pointer * per_frame_zoom_ratio
    _delta_offset = Vector2(
            pan_zoom_control_weight_x * max_pan_distance_per_frame,
            pan_zoom_control_weight_y * max_pan_distance_per_frame)
    _delta_zoom_multiplier = \
            max(abs(pan_zoom_control_weight_x),
                abs(pan_zoom_control_weight_y)) * \
            max_zoom_delta_per_frame


func _update_camera_from_deltas() -> void:
    assert(_delta_offset != Vector2.INF)
    assert(!is_inf(_delta_zoom_multiplier))
    
    # Calculate the next values.
    var next_offset: Vector2
    var next_zoom_multiplier: float
    if Su.snaps_camera_back_to_character:
        next_offset = _target_offset + _delta_offset
        next_zoom_multiplier = _target_zoom_multiplier + _delta_zoom_multiplier
    else:
        next_offset = _target_offset + _delta_offset
        next_zoom_multiplier = 1.0
    
    # Don't let the pan and zoom exceed their max bounds.
    next_offset.x = clamp(
            next_offset.x,
            -Su.max_pan_distance_from_pointer,
            Su.max_pan_distance_from_pointer)
    next_offset.y = clamp(
            next_offset.y,
            -Su.max_pan_distance_from_pointer,
            Su.max_pan_distance_from_pointer)
    next_zoom_multiplier = clamp(
            next_zoom_multiplier,
            1.0,
            Su.max_zoom_multiplier_from_pointer)
    
    _update_camera(next_offset, next_zoom_multiplier)


func _update_camera(
        next_offset: Vector2,
        next_zoom_multiplier: float) -> void:
    _target_offset = next_offset
    _target_zoom_multiplier = next_zoom_multiplier
    
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
    Sc.camera_controller.offset += delta


func _update_zoom(zoom_multiplier: float) -> void:
    var delta := zoom_multiplier - self._tween_zoom_multiplier
    self._tween_zoom_multiplier = zoom_multiplier
    Sc.camera_controller.zoom_factor += delta
