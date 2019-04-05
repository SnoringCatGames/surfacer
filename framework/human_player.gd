extends Player
class_name HumanPlayer

# Gets low-level input for the current frame.
#
# This can be overridden separately for the human and computer players:
# - The computer player will use instruction sets.
# - The human player will use system IO.
func _get_current_input(delta: float) -> Dictionary:
    var actions := {
        delta = delta,
        just_pressed_jump = Input.is_action_just_pressed("jump"),
        pressed_jump = Input.is_action_pressed("jump"),
        pressed_up = Input.is_action_pressed("move_up"),
        pressed_down = Input.is_action_pressed("move_down"),
        pressed_left = Input.is_action_pressed("move_left"),
        pressed_right = Input.is_action_pressed("move_right"),
        horizontal_movement_sign = 0,
        which_wall = _get_which_wall_collided(),
        is_on_floor = is_on_floor(),
        is_on_ceiling = is_on_ceiling(),
        is_on_wall = is_on_wall(),
        is_on_left_wall = false,
        is_on_right_wall = false,
        facing_wall = false,
        pressing_into_wall = false,
        pressing_away_from_wall = false,
    }
    
    if actions.pressed_left:
        actions.horizontal_movement_sign = -1
    elif actions.pressed_right:
        actions.horizontal_movement_sign = 1
    
    actions.is_on_left_wall = actions.which_wall == "left"
    actions.is_on_right_wall = actions.which_wall == "right"
     
    actions.facing_wall = \
        (actions.which_wall == "right" and horizontal_facing_sign > 0) or \
        (actions.which_wall == "left" and horizontal_facing_sign < 0)
    actions.pressing_into_wall = \
        (actions.which_wall == "right" and actions.pressed_right) or \
        (actions.which_wall == "left" and actions.pressed_left)
    actions.pressing_away_from_wall = \
        (actions.which_wall == "right" and actions.pressed_left) or \
        (actions.which_wall == "left" and actions.pressed_right)
    
    return actions
