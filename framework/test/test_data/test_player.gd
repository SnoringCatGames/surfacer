extends HumanPlayer
class_name TestPlayer

const FRICTION_MULTIPLIER := 0.01 # For calculating friction for walking

var is_ascending_from_jump := false
var jump_count := 0

var _can_dash := true

var _dash_cooldown_timer: Timer
var _dash_fade_tween: Tween

func _init().("test") -> void:
    pass

func _ready() -> void:
    # Set up a Tween for the fade-out at the end of a dash.
    _dash_fade_tween = Tween.new()
    add_child(_dash_fade_tween)
    
    # Set up a Timer for the dash cooldown.
    _dash_cooldown_timer = Timer.new()
    _dash_cooldown_timer.one_shot = true
    #warning-ignore:return_value_discarded
    _dash_cooldown_timer.connect("timeout", self, "_dash_cooldown_finished")
    add_child(_dash_cooldown_timer)
    
    # Start facing the right.
    surface_state.horizontal_facing_sign = 1
#    $CatAnimator.face_right()

# Gets actions for the current frame.
#
# Stores these additional actions on the action map.
# {
#   start_dash,
# }
func _update_actions(delta: float) -> void:
    ._update_actions(delta)
    
    actions.start_dash = _can_dash and Input.is_action_just_pressed("dash")

# Updates physics and player states in response to the current actions.
func _process_actions() -> void:
    # Flip the horizontal direction of the animation according to which way the player is facing.
#    if actions.pressed_left:
#        $CatAnimator.face_left()
#    if actions.pressed_right:
#        $CatAnimator.face_right()
    
    # Cancel any horizontal velocity when bumping into a wall.
    if surface_state.is_touching_wall:
        # The move_and_slide system depends on maintained velocity always pushing the player into a
        # collision, otherwise it will eventually stop the collision. If we just zero this out,
        # is_on_wall() will give false negatives.
        velocity.x = movement_params.min_speed_to_maintain_horizontal_collision * \
                surface_state.toward_wall_sign
    
    if surface_state.is_grabbing_wall:
        _process_actions_while_on_wall()
    elif surface_state.is_grabbing_floor:
        _process_actions_while_on_floor()
    else:
        _process_actions_while_in_air()

#warning-ignore:unused_argument
func _process_actions_while_on_floor() -> void:
    jump_count = 0
    is_ascending_from_jump = false
    
    # The move_and_slide system depends on some vertical gravity always pushing the player into
    # the floor. If we just zero this out, is_on_floor() will give false negatives.
    velocity.y = movement_params.min_speed_to_maintain_vertical_collision
    
    # Horizontal movement.
    velocity.x += movement_params.walk_acceleration * surface_state.horizontal_movement_sign
    
    # Friction.
    var friction_offset: float = Utils.get_floor_friction_coefficient(self) * \
            FRICTION_MULTIPLIER * movement_params.gravity_fast_fall
    friction_offset = clamp(friction_offset, 0, abs(velocity.x))
    velocity.x += -sign(velocity.x) * friction_offset
    
    # Fall-through floor.
    if surface_state.is_falling_through_floors:
        # TODO: If we were already falling through the air, then we should instead maintain the previous velocity here.
        velocity.y = movement_params.fall_through_floor_velocity_boost
        
    # Jump.
    elif actions.just_pressed_jump:
        jump_count = 1
        is_ascending_from_jump = true
        velocity.y = movement_params.jump_boost
    
    # Dash.
    if actions.start_dash:
        _start_dash(surface_state.horizontal_facing_sign)
    
    # Walking animation.
#    if actions.pressed_left or actions.pressed_right:
#        $CatAnimator.walk()
#    else:
#        $CatAnimator.rest()

func _process_actions_while_in_air() -> void:
    # If the player falls off a wall or ledge, then that's considered the first jump.
    jump_count = max(jump_count, 1)
    
    var is_first_jump := jump_count == 1
    
    velocity = PlayerMovement.update_velocity_in_air( \
            velocity, actions.delta, actions.pressed_jump, is_first_jump,
            surface_state.horizontal_movement_sign, movement_params)
    
    # Hit ceiling.
    if surface_state.is_touching_ceiling:
        is_ascending_from_jump = false
        velocity.y = movement_params.min_speed_to_maintain_vertical_collision
    
    # Double jump.
    if actions.just_pressed_jump and jump_count < movement_params.max_jump_chain:
        jump_count += 1
        is_ascending_from_jump = true
        velocity.y = movement_params.jump_boost
    
    # Dash.
    if actions.start_dash:
        _start_dash(surface_state.horizontal_facing_sign)
    
    # Animate.
#    if velocity.y > 0:
#        $CatAnimator.jump_descend()
#    else:
#        $CatAnimator.jump_ascend()

#warning-ignore:unused_argument
func _process_actions_while_on_wall() -> void:
    jump_count = 0
    is_ascending_from_jump = false
    velocity.y = 0
    
    # Wall jump.
    if actions.just_pressed_jump:
        surface_state.is_grabbing_wall = false
        jump_count = 1
        is_ascending_from_jump = true
        
        velocity.y = movement_params.jump_boost
        
        # Give a little boost to get the player away from the wall, so they can still be
        # pushing themselves into the wall when they start the jump.
        velocity.x = -surface_state.toward_wall_sign * \
                movement_params.in_air_horizontal_acceleration * \
                movement_params.wall_jump_horizontal_multiplier
    
    # Fall off.
    elif surface_state.is_pressing_away_from_wall:
        surface_state.is_grabbing_wall = false
    
    # Start walking.
    elif surface_state.is_touching_floor and actions.pressed_down:
        surface_state.is_grabbing_wall = false
    
    # Climb up.
    elif actions.pressed_up:
        velocity.y = movement_params.climb_up_speed
#        $CatAnimator.climb_up()
    
    # Climb down.
    elif actions.pressed_down:
        velocity.y = movement_params.climb_down_speed
#        $CatAnimator.climb_down()
        
    # Rest.
#    else:
#        $CatAnimator.rest_on_wall()
    
    if actions.start_dash:
        _start_dash(-surface_state.toward_wall_sign)

func _start_dash(horizontal_movement_sign: int) -> void:
    if !_can_dash:
        return
    
    movement_params.current_max_horizontal_speed = movement_params.max_horizontal_speed_default * \
            movement_params.dash_speed_multiplier
    velocity.x = movement_params.current_max_horizontal_speed * horizontal_movement_sign
    
    velocity.y += movement_params.dash_vertical_boost
    
    _dash_cooldown_timer.start(movement_params.dash_cooldown)
    #warning-ignore:return_value_discarded
    _dash_fade_tween.reset_all()
    #warning-ignore:return_value_discarded
    _dash_fade_tween.interpolate_property(self, "movement_params.current_max_horizontal_speed", \
            movement_params.max_horizontal_speed_default * movement_params.dash_speed_multiplier, \
            movement_params.max_horizontal_speed_default, movement_params.dash_fade_duration, \
            Tween.TRANS_LINEAR, Tween.EASE_IN, \
            movement_params.dash_duration - movement_params.dash_fade_duration)
    #warning-ignore:return_value_discarded
    _dash_fade_tween.start()
    
#    if horizontal_movement_sign > 0:
#        $CatAnimator.face_right()
#    else:
#        $CatAnimator.face_left()

func _dash_cooldown_finished() -> void:
    _can_dash = true
