extends Player
class_name HumanPlayer

func _init(player_name: String).(player_name) -> void:
    pass

# Gets actions for the current frame.
#
# This can be overridden separately for the human and computer players:
# - The computer player will use instruction sets.
# - The human player will use system IO.
func _update_actions(delta: float) -> void:
    actions.just_pressed_jump = Input.is_action_just_pressed("jump")
    actions.pressed_jump = Input.is_action_pressed("jump")
    actions.pressed_up = Input.is_action_pressed("move_up")
    actions.pressed_down = Input.is_action_pressed("move_down")
    actions.pressed_left = Input.is_action_pressed("move_left")
    actions.pressed_right = Input.is_action_pressed("move_right")
