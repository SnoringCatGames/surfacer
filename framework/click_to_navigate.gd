extends Node
class_name ClickToNavigate

var level # TODO: Add type back in
var computer_player: ComputerPlayer
var navigator: PlatformGraphNavigator

func update_level(level) -> void:
    self.level = level
    
    # Get a reference to the ComputerPlayer.
    var computer_players: Array = level.get_tree().get_nodes_in_group("computer_players")
    assert(computer_players.size() == 1)
    computer_player = computer_players[0]
    navigator = computer_player.platform_graph_navigator

func _process(delta: float) -> void:
    if Input.is_action_just_released("left_click"):
        var position: Vector2 = level.get_global_mouse_position()
        navigator.start_new_navigation(position)
