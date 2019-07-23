extends Node
class_name ClickToNavigate

var level # TODO: Add type back in
var player: Player
var navigator: Navigator

func update_level(level) -> void:
    self.level = level
    set_player(level.computer_player)

func set_player(player: Player) -> void:
    if player != null:
        self.player = player
        navigator = player.navigator
    else:
        self.player = null
        navigator = null

func _process(delta: float) -> void:
    if navigator == null:
        return
    
    if Input.is_action_just_released("left_click"):
        var position: Vector2 = level.get_global_mouse_position()
        navigator.navigate_to_nearest_surface(position)
