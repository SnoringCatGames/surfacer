extends Player
class_name HumanPlayer

func _init(player_name: String).(player_name) -> void:
    pass

# Gets actions for the current frame.
#
# This can be overridden separately for the human and computer players:
# - The computer player will use instruction sets.
# - The human player will use system IO.
# FIXME:
# - Refactor to use a custom class (like SurfaceState) instead of a Dictionary
# - Update the pre-configured Input Map in Project Settings to use more semantic keys instead of just up/down/etc.
# - Document in a separate markdown file exactly which Input Map keys this framework depends on.
func _get_actions(delta: float) -> Dictionary:
    var actions := {
        delta = delta,
        just_pressed_jump = Input.is_action_just_pressed("jump"),
        pressed_jump = Input.is_action_pressed("jump"),
        pressed_up = Input.is_action_pressed("move_up"),
        pressed_down = Input.is_action_pressed("move_down"),
        pressed_left = Input.is_action_pressed("move_left"),
        pressed_right = Input.is_action_pressed("move_right"),
    }
    
    return actions
