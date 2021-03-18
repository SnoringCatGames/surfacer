extends Node2D
class_name PlayerPointerHandler

const DRAG_THROTTLE_INTERVAL_SEC := 0.1

var player
var throttled_set_new_drag_position: FuncRef = Time.throttle( \
        funcref(self, "set_new_drag_position"), \
        DRAG_THROTTLE_INTERVAL_SEC)
var last_pointer_drag_position := Vector2.INF

func _init(player) -> void:
    self.player = player

func _unhandled_input(event: InputEvent) -> void:
    if SurfacerConfig.current_player_for_clicks != player:
        return
    
    var pointer_up_position := Vector2.INF
    var pointer_drag_position := Vector2.INF
    var event_type := "UNKNOWN_INP"
    
    # Mouse-up: Position selection.
    if event is InputEventMouseButton and \
            event.button_index == BUTTON_LEFT and \
            !event.pressed and \
            !event.control:
        event_type = "MOUSE_UP   "
        pointer_up_position = ScaffoldConfig.level.get_global_mouse_position()
    
    # Mouse-down: Position pre-selection.
    if event is InputEventMouseButton and \
            event.button_index == BUTTON_LEFT and \
            event.pressed and \
            !event.control:
        event_type = "MOUSE_DOWN "
        pointer_drag_position = \
                ScaffoldConfig.level.get_global_mouse_position()
    
    # Mouse-move: Position pre-selection.
    if event is InputEventMouseMotion and \
            last_pointer_drag_position != Vector2.INF:
        event_type = "MOUSE_DRAG "
        pointer_drag_position = \
                ScaffoldConfig.level.get_global_mouse_position()
    
    # Touch-up: Position selection.
    if event is InputEventScreenTouch and \
            !event.pressed:
        event_type = "TOUCH_UP   "
        pointer_up_position = ScaffoldUtils.get_global_touch_position(event)
    
    # Touch-down: Position pre-selection.
    if event is InputEventScreenTouch and \
            event.pressed:
        event_type = "TOUCH_DOWN "
        pointer_drag_position = ScaffoldUtils.get_global_touch_position(event)
    
    # Touch-move: Position pre-selection.
    if event is InputEventScreenDrag:
        event_type = "TOUCH_DRAG "
        pointer_drag_position = ScaffoldUtils.get_global_touch_position(event)
    
#    if pointer_up_position != Vector2.INF or \
#            pointer_drag_position != Vector2.INF:
#        player.print_msg("%s:         %8.3fs", [ \
#                event_type, \
#                Time.elapsed_play_time_actual_sec, \
#            ])
    
    if pointer_up_position != Vector2.INF:
        last_pointer_drag_position = Vector2.INF
        Time.cancel_pending_throttle(throttled_set_new_drag_position)
        
        player.new_selection_target = pointer_up_position
        player.new_selection_position = \
                _get_nearest_surface_position_within_distance_threshold( \
                        pointer_up_position, \
                        player)
        
    elif pointer_drag_position != Vector2.INF:
        last_pointer_drag_position = pointer_drag_position
        throttled_set_new_drag_position.call_func()

func set_new_drag_position() -> void:
    player.preselection_target = last_pointer_drag_position
    player.preselection_position = \
            _get_nearest_surface_position_within_distance_threshold( \
                    last_pointer_drag_position, \
                    player)

static func _get_nearest_surface_position_within_distance_threshold( \
        target: Vector2, \
        player) -> PositionAlongSurface:
    var closest_position := SurfaceParser.find_closest_position_on_a_surface( \
            target, \
            player)
    if closest_position.target_point.distance_squared_to(target) <= \
            Navigator.NEARBY_SURFACE_DISTANCE_THRESHOLD * \
            Navigator.NEARBY_SURFACE_DISTANCE_THRESHOLD:
        # The nearest position-along-a-surface is close enough to use.
        return closest_position
    return null
