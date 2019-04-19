extends Reference
class_name ClickToNavigate

var level: Level
var computer_player: ComputerPlayer
var navigator: PlatformGraphNavigator

func _update_level(level: Level) -> void:
    self.level = level
    
    # Get a reference to the ComputerPlayer.
    var computer_players = level.get_tree().get_nodes_in_group("computer_players")
    assert(computer_players.size() == 1)
    computer_player = computer_players[0]
    navigator = computer_player.platform_graph_navigator

func _process(delta: float) -> void:
    if Input.is_action_just_released("left_click"):
        var position = level.get_global_mouse_position()
        navigator.start_new_navigation(position)
