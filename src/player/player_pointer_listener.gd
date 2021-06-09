class_name PlayerPointerListener
extends Node2D


var _player
var _nearby_surface_distance_squared_threshold: float
var _is_preselection_path_update_pending := false
var _throttled_update_preselection_path: FuncRef = Gs.time.throttle(
        funcref(self, "_update_preselection_path"),
        Surfacer.path_drag_update_throttle_interval)
var _throttled_update_preselection_beats: FuncRef = Gs.time.throttle(
        funcref(self, "_update_preselection_beats"),
        Surfacer.path_beat_update_throttle_interval)
var _last_pointer_drag_position := Vector2.INF


func _init(player) -> void:
    self._player = player
    var nearby_surface_distance_threshold: float = \
            _player.movement_params.max_upward_jump_distance * \
            PointerSelectionPosition.SURFACE_TO_AIR_THRESHOLD_MAX_JUMP_RATIO
    self._nearby_surface_distance_squared_threshold = \
            nearby_surface_distance_threshold * \
            nearby_surface_distance_threshold


func _process(_delta: float) -> void:
    if _last_pointer_drag_position != Vector2.INF:
        _throttled_update_preselection_beats.call_func()


func _unhandled_input(event: InputEvent) -> void:
    if !Gs.is_user_interaction_enabled or \
            Surfacer.human_player != _player:
        return
    
    var pointer_up_position := Vector2.INF
    var pointer_drag_position := Vector2.INF
    var event_type := "UNKNOWN_INP"
    
    # NOTE: Shouldn't need to handle mouse events, since we should be emulating
    #       touch events.
    
#    # Mouse-up: Position selection.
#    if event is InputEventMouseButton and \
#            event.button_index == BUTTON_LEFT and \
#            !event.pressed and \
#            !event.control:
#        event_type = "MOUSE_UP   "
#        pointer_up_position = Gs.utils.get_level_touch_position(event)
#
#    # Mouse-down: Position pre-selection.
#    if event is InputEventMouseButton and \
#            event.button_index == BUTTON_LEFT and \
#            event.pressed and \
#            !event.control:
#        event_type = "MOUSE_DOWN "
#        pointer_drag_position = \
#                Gs.utils.get_level_touch_position(event)
#
#    # Mouse-move: Position pre-selection.
#    if event is InputEventMouseMotion and \
#            _last_pointer_drag_position != Vector2.INF:
#        event_type = "MOUSE_DRAG "
#        pointer_drag_position = \
#                Gs.utils.get_level_touch_position(event)
    
    var is_control_pressed := \
            Gs.level_input.is_key_pressed(KEY_CONTROL) or \
            Gs.level_input.is_key_pressed(KEY_META)
    
    # Touch-up: Position selection.
    if event is InputEventScreenTouch and \
            !event.pressed and \
            !is_control_pressed:
        event_type = "TOUCH_UP   "
        pointer_up_position = Gs.utils.get_level_touch_position(event)
    
    # Touch-down: Position pre-selection.
    if event is InputEventScreenTouch and \
            event.pressed and \
            !is_control_pressed:
        event_type = "TOUCH_DOWN "
        pointer_drag_position = Gs.utils.get_level_touch_position(event)
    
    # Touch-move: Position pre-selection.
    if event is InputEventScreenDrag and \
            !is_control_pressed:
        event_type = "TOUCH_DRAG "
        pointer_drag_position = Gs.utils.get_level_touch_position(event)
    
#    if pointer_up_position != Vector2.INF or \
#            pointer_drag_position != Vector2.INF:
#        _player.print_msg("%s:         %8.3fs", [
#                event_type,
#                Gs.time.get_play_time(),
#            ])
    
    if pointer_up_position != Vector2.INF:
        _on_pointer_released(pointer_up_position)
    elif pointer_drag_position != Vector2.INF:
        _on_pointer_moved(pointer_drag_position)


func _update_preselection_path() -> void:
    _is_preselection_path_update_pending = false
    _player.pre_selection.update_pointer_position(_last_pointer_drag_position)


func _update_preselection_beats() -> void:
    # Skip the beat update if we're already going to the the whole path update.
    if !_is_preselection_path_update_pending:
        _player.pre_selection.update_beats()


func _on_pointer_released(pointer_position: Vector2) -> void:
    _last_pointer_drag_position = Vector2.INF
    Gs.slow_motion.set_slow_motion_enabled(false)
    _is_preselection_path_update_pending = false
    Gs.time.cancel_pending_throttle(_throttled_update_preselection_path)
    Gs.time.cancel_pending_throttle(_throttled_update_preselection_beats)
    _player.new_selection.update_pointer_position(pointer_position)
    
    var selected_surface: Surface = \
            _player.new_selection.navigation_destination.surface if \
            _player.new_selection.navigation_destination != null else \
            null
    var is_surface_navigatable: bool = _player.new_selection.path != null
    Surfacer.annotators.add_transient(ClickAnnotator.new(
            pointer_position,
            selected_surface,
            is_surface_navigatable))


func _on_pointer_moved(pointer_position: Vector2) -> void:
    _last_pointer_drag_position = pointer_position
    Gs.slow_motion.set_slow_motion_enabled(true)
    _is_preselection_path_update_pending = true
    _throttled_update_preselection_path.call_func()


func on_player_moved() -> void:
    if _last_pointer_drag_position != Vector2.INF:
        Gs.slow_motion.set_slow_motion_enabled(true)
        _throttled_update_preselection_path.call_func()
