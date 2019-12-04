extends Node
class_name ClickToNavigate

var global
var player: Player
var navigator: Navigator

func _ready() -> void:
    self.global = $"/root/Global"

func set_player(player: Player) -> void:
    if player != null:
        self.player = player
        navigator = player.navigator
    else:
        self.player = null
        navigator = null

func _unhandled_input(event: InputEvent) -> void:
    if navigator == null:
        return
    
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and !event.pressed:
        var position: Vector2 = global.current_level.get_global_mouse_position()
        navigator.navigate_to_nearest_surface(position)
