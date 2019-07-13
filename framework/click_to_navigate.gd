extends Node
class_name ClickToNavigate

var level # TODO: Add type back in
var computer_player: ComputerPlayer
var navigator: PlatformGraphNavigator

func update_level(level) -> void:
    self.level = level
    set_computer_player(level.computer_player)

func set_computer_player(computer_player: ComputerPlayer) -> void:
    if computer_player != null:
        self.computer_player = computer_player
        navigator = computer_player.platform_graph_navigator
    else:
        self.computer_player = null
        navigator = null

func _process(delta: float) -> void:
    if navigator == null:
        return
    
    if Input.is_action_just_released("left_click"):
        var position: Vector2 = level.get_global_mouse_position()
        navigator.start_new_navigation(position)
