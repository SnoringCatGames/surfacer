extends Node2D
class_name PlayerPointerHandler

var global # TODO: Add type back
var player

func _init(player) -> void:
    self.player = player

func _ready() -> void:
    self.global = $"/root/Global"

func _unhandled_input(event: InputEvent) -> void:
    if global.current_player_for_clicks != player:
        return
    
    var pointer_up_position := Vector2.INF
    var pointer_drag_position := Vector2.INF
    
    # Mouse-up: Position selection.
    if event is InputEventMouseButton and \
            event.button_index == BUTTON_LEFT and \
            !event.pressed and \
            !event.control:
        pointer_up_position = global.current_level.get_global_mouse_position()
    
    # Mouse-down: Position pre-selection.
    if event is InputEventMouseButton and \
            event.button_index == BUTTON_LEFT and \
            event.pressed and \
            !event.control:
        pointer_drag_position = global.current_level.get_global_mouse_position()
    
    # Mouse-move: Position pre-selection.
    if event is InputEventMouseMotion and \
            player.preselection_target != Vector2.INF:
        pointer_drag_position = global.current_level.get_global_mouse_position()
    
    # Touch-up: Position selection.
    if event is InputEventScreenTouch and \
            !event.pressed:
        pointer_up_position = Utils.get_global_touch_position( \
                event, \
                self)
    
    # Touch-down: Position pre-selection.
    if event is InputEventScreenTouch and \
            event.pressed:
        pointer_drag_position = Utils.get_global_touch_position( \
                event, \
                self)
    
    # Touch-move: Position pre-selection.
    if event is InputEventScreenDrag:
        pointer_drag_position = Utils.get_global_touch_position( \
                event, \
                self)
    
    if pointer_up_position != Vector2.INF:
        player.new_selection_target = pointer_up_position
        player.new_selection_position = _get_nearest_surface_position_within_distance_threshold( \
                pointer_up_position, \
                player)
        
    elif pointer_drag_position != Vector2.INF:
        # FIXME: ---------------------- Consider debouncing this.
        player.preselection_target = pointer_drag_position
        player.preselection_position = _get_nearest_surface_position_within_distance_threshold( \
                pointer_drag_position, \
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
