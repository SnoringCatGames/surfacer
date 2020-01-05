extends Node
class_name ClickToNavigate

var global

func _ready() -> void:
    self.global = $"/root/Global"

func _unhandled_input(event: InputEvent) -> void:
    if global.current_player_for_clicks == null:
        return
    
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and \
            !event.pressed and !event.control:
        var position: Vector2 = global.current_level.get_global_mouse_position()
        global.current_player_for_clicks.navigator.navigate_to_nearby_surface(position)
