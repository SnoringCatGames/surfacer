class_name PlayerPointerHandler
extends Node2D

const DRAG_THROTTLE_INTERVAL_SEC := 0.1

var player
var throttled_set_new_drag_position: FuncRef = Gs.time.throttle(
        funcref(self, "set_new_drag_position"),
        DRAG_THROTTLE_INTERVAL_SEC)
var last_pointer_drag_position := Vector2.INF

func _init(player) -> void:
    self.player = player

func _unhandled_input(event: InputEvent) -> void:
    if !Gs.is_user_interaction_enabled or \
            Surfacer.human_player != player:
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
#        pointer_up_position = Gs.utils.get_global_touch_position(event)
#
#    # Mouse-down: Position pre-selection.
#    if event is InputEventMouseButton and \
#            event.button_index == BUTTON_LEFT and \
#            event.pressed and \
#            !event.control:
#        event_type = "MOUSE_DOWN "
#        pointer_drag_position = \
#                Gs.utils.get_global_touch_position(event)
#
#    # Mouse-move: Position pre-selection.
#    if event is InputEventMouseMotion and \
#            last_pointer_drag_position != Vector2.INF:
#        event_type = "MOUSE_DRAG "
#        pointer_drag_position = \
#                Gs.utils.get_global_touch_position(event)
    
    var is_control_pressed := \
            Gs.level_input.is_key_pressed(KEY_CONTROL) or \
            Gs.level_input.is_key_pressed(KEY_META)
    
    # Touch-up: Position selection.
    if event is InputEventScreenTouch and \
            !event.pressed and \
            !is_control_pressed:
        event_type = "TOUCH_UP   "
        pointer_up_position = Gs.utils.get_global_touch_position(event)
    
    # Touch-down: Position pre-selection.
    if event is InputEventScreenTouch and \
            event.pressed and \
            !is_control_pressed:
        event_type = "TOUCH_DOWN "
        pointer_drag_position = Gs.utils.get_global_touch_position(event)
    
    # Touch-move: Position pre-selection.
    if event is InputEventScreenDrag and \
            !is_control_pressed:
        event_type = "TOUCH_DRAG "
        pointer_drag_position = Gs.utils.get_global_touch_position(event)
    
#    if pointer_up_position != Vector2.INF or \
#            pointer_drag_position != Vector2.INF:
#        player.print_msg("%s:         %8.3fs", [
#                event_type,
#                Gs.time.get_play_time_sec(),
#            ])
    
    if pointer_up_position != Vector2.INF:
        last_pointer_drag_position = Vector2.INF
        Gs.time.cancel_pending_throttle(throttled_set_new_drag_position)
        
        player.new_selection_target = pointer_up_position
        player.new_selection_position = \
                SurfaceParser.find_closest_position_on_a_surface(
                            pointer_up_position,
                            player,
                            Navigator.NEARBY_SURFACE_DISTANCE_THRESHOLD * \
                            Navigator.NEARBY_SURFACE_DISTANCE_THRESHOLD)
        
    elif pointer_drag_position != Vector2.INF:
        last_pointer_drag_position = pointer_drag_position
        throttled_set_new_drag_position.call_func()

func set_new_drag_position() -> void:
    player.preselection_target = last_pointer_drag_position
    player.preselection_position = \
            SurfaceParser.find_closest_position_on_a_surface(
                    last_pointer_drag_position,
                    player,
                    Navigator.NEARBY_SURFACE_DISTANCE_THRESHOLD * \
                    Navigator.NEARBY_SURFACE_DISTANCE_THRESHOLD)
