extends Player
class_name HumanPlayer

# Gets actions for the current frame.
#
# This can be overridden separately for the human and computer players:
# - The computer player will use instruction sets.
# - The human player will use system IO.
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

# TODO: doc
func _update_surface_state(actions: Dictionary) -> void:
    # Flip the horizontal direction of the animation according to which way the player is facing.
    if actions.pressed_right:
        surface_state.horizontal_facing_sign = 1
        surface_state.horizontal_movement_sign = 1
    elif actions.pressed_left:
        surface_state.horizontal_facing_sign = -1
        surface_state.horizontal_movement_sign = -1
    else:
        surface_state.horizontal_movement_sign = 0
    
    surface_state.is_on_floor = is_on_floor()
    surface_state.is_touching_ceiling = is_on_ceiling()
    surface_state.is_touching_wall = is_on_wall()
    surface_state.which_wall = _get_which_wall_collided()
    surface_state.is_touching_left_wall = surface_state.which_wall == "left"
    surface_state.is_touching_right_wall = surface_state.which_wall == "right"
    
    # Calculate the sign of a colliding wall's direction.
    surface_state.toward_wall_sign = (0 if !surface_state.is_touching_wall else \
            (1 if surface_state.which_wall == "right" else -1))
    
    surface_state.is_facing_wall = \
        (surface_state.which_wall == "right" and surface_state.horizontal_facing_sign > 0) or \
        (surface_state.which_wall == "left" and surface_state.horizontal_facing_sign < 0)
    surface_state.is_pressing_into_wall = \
        (surface_state.which_wall == "right" and actions.pressed_right) or \
        (surface_state.which_wall == "left" and actions.pressed_left)
    surface_state.is_pressing_away_from_wall = \
        (surface_state.which_wall == "right" and actions.pressed_left) or \
        (surface_state.which_wall == "left" and actions.pressed_right)
    
    var facing_into_wall_and_pressing_up: bool = actions.pressed_up and (surface_state.is_facing_wall or surface_state.is_pressing_into_wall)
    surface_state.is_triggering_wall_grab = surface_state.is_pressing_into_wall or facing_into_wall_and_pressing_up
    
    surface_state.is_triggering_fall_through = actions.pressed_down and actions.just_pressed_jump
    
    # Detect changes to wall grab state.
    if !surface_state.is_touching_wall:
        surface_state.is_grabbing_wall = false
    elif surface_state.is_triggering_wall_grab:
        surface_state.is_grabbing_wall = true
