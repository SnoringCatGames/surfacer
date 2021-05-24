class_name CameraPanController
extends Node2D

const _PAN_THROTTLE_INTERVAL_SEC := 0.05
const _TWEEN_DURATION := 0.1

var _last_pointer_position := Vector2.INF
var _throttled_set_new_drag_position: FuncRef = Gs.time.throttle(
        funcref(self, "_update_camera_from_pointer"),
        _PAN_THROTTLE_INTERVAL_SEC)

var _tween: ScaffolderTween

var _offset := Vector2.ZERO
var _zoom_multiplier := 1.0

func _init() -> void:
    _tween = ScaffolderTween.new()
    add_child(_tween)

func _unhandled_input(event: InputEvent) -> void:
    if !Gs.is_user_interaction_enabled:
        return
    
    var is_control_pressed := \
            Gs.level_input.is_key_pressed(KEY_CONTROL) or \
            Gs.level_input.is_key_pressed(KEY_META)
    
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
        pointer_drag_position = Gs.utils.get_level_touch_position(event)
    
    # Touch-move: Position pre-selection.
    if event is InputEventScreenDrag:
        pointer_drag_position = Gs.utils.get_level_touch_position(event)
    
    if pointer_drag_position != Vector2.INF:
        _update_drag(pointer_drag_position)

# FIXME: ------------------------------------------
# - Move these flags out to Surfacer.
var keeps_camera_anchored_on_player := true
var max_zoom_multiplier_from_pointer := 1.5
var max_pan_distance_from_pointer := 1024.0
var duration_to_max_pan_and_zoom_from_pointer_at_max_control := 1.0
var screen_size_ratio_distance_from_edge_to_start_pan_from_pointer := 0.25
func _validate() -> void:
    assert(max_zoom_multiplier_from_pointer >= 0.0)
    assert(screen_size_ratio_distance_from_edge_to_start_pan_from_pointer <= \
            0.5)

func _stop_drag() -> void:
    _last_pointer_position = Vector2.INF
    Gs.time.cancel_pending_throttle(_throttled_set_new_drag_position)
    if keeps_camera_anchored_on_player:
        _update_camera(Vector2.ZERO, 1.0)

func _update_drag(pointer_position: Vector2) -> void:
    _last_pointer_position = pointer_position
    _throttled_set_new_drag_position.call_func()

func _update_camera_from_pointer() -> void:
    assert(_last_pointer_position != Vector2.INF)
    
    # FIXME: LEFT OFF HERE: ---------------------------------------------------
    # - update camera pan and zoom, depending on:
    #   - rates given in a Surfacer flag
    #   - the player's current position (depending on the same Surfacer flag
    #     used for maybe reverting pan and zoom when cancelling drag)
    #   - how close the drag position is to the edge of the viewport
    #   - how close the pan and zoom are to the max allowed values, as
    #     configured in Surfacer
    # 
    #var keeps_camera_anchored_on_player := true
    #var max_zoom_multiplier_from_pointer := 1.5
    #var max_pan_distance_from_pointer := 1024.0
    #var duration_to_max_pan_and_zoom_from_pointer_at_max_control := 1.0
    #var screen_size_ratio_distance_from_edge_to_start_pan_from_pointer := 0.25
    pass
    
    
    var pointer_max_control_bounds := Gs.camera_controller.get_bounds()
    var camera_center := \
            pointer_max_control_bounds.position + \
            pointer_max_control_bounds.size / 2.0
    var min_control_bounds_size := \
            pointer_max_control_bounds.size * \
            (1 - \
            screen_size_ratio_distance_from_edge_to_start_pan_from_pointer * 2)
    var min_control_bounds_position := \
            pointer_max_control_bounds.position + \
            pointer_max_control_bounds.size * \
            screen_size_ratio_distance_from_edge_to_start_pan_from_pointer
    var pointer_min_control_bounds := Rect2(
            min_control_bounds_position,
            min_control_bounds_size)
    
    var pan_zoom_control_weight_x: float
    if _last_pointer_position.x < camera_center.x:
        pass
    else:
        pass
    var pan_zoom_control_weight_y: float
    if _last_pointer_position.y < camera_center.y:
        pass
    else:
        pass
    
    
    
    
    
    var next_offset: Vector2
    var next_zoom_multiplier: float
    if keeps_camera_anchored_on_player:
        pass
    else:
        next_zoom_multiplier = 1.0
        pass
    
    
    
#    _update_camera(next_offset, next_zoom_multiplier)

func _update_camera(
        pan: Vector2,
        zoom: float) -> void:
    _tween.stop_all()
    _tween.interpolate_method(
            self,
            "_update_pan",
            _offset,
            pan,
            _TWEEN_DURATION,
            "ease_in_out",
            0.0,
            TimeType.PLAY_PHYSICS_SCALED)
    _tween.interpolate_method(
            self,
            "_update_zoom",
            _zoom_multiplier,
            zoom,
            _TWEEN_DURATION,
            "ease_in_out",
            0.0,
            TimeType.PLAY_PHYSICS_SCALED)
    _tween.start()

func _update_pan(offset: Vector2) -> void:
    var delta := offset - self._offset
    self._offset = offset
    Gs.camera_controller.offset += delta

func _update_zoom(zoom_multiplier: float) -> void:
    var delta := zoom_multiplier - self._zoom_multiplier
    self._zoom_multiplier = zoom_multiplier
    Gs.camera_controller.zoom_factor += delta
