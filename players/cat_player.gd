extends HumanPlayer
class_name CatPlayer

const SLOW_JUMP_ASCENT_GRAVITY_MULTIPLIER := .38
const SLOW_DOUBLE_JUMP_ASCENT_GRAVITY_MULTIPLIER := .68
const WALK_SPEED := 350.0
const FRICTION_MULTIPLIER := 0.01 # For calculating friction for walking
const IN_AIR_HORIZONTAL_SPEED := 300.0
const DEFAULT_MAX_HORIZONTAL_SPEED := 400.0
const MIN_HORIZONTAL_SPEED := 50.0
const MAX_VERTICAL_SPEED := 4000.0
const MIN_VERTICAL_SPEED := 0.0
const CLIMB_UP_SPEED := -350.0
const CLIMB_DOWN_SPEED := 150.0
const JUMP_SPEED := -1000.0
const WALL_JUMP_HORIZONTAL_MULTIPLIER := .5
const MAX_JUMP_CHAIN := 2
const DASH_SPEED_MULTIPLIER := 4.0
const DASH_VERTICAL_SPEED := -400.0
const DASH_DURATION := .3
const DASH_FADE_DURATION := .1
const DASH_COOLDOWN := 1.0
const FALL_THROUGH_FLOOR_VELOCITY_BOOST := 100.0
const MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION := 15.0
const MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION := MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION * 4.0

var velocity := Vector2()
var is_ascending_from_jump := false
var jump_count := 0

var _current_max_horizontal_speed := DEFAULT_MAX_HORIZONTAL_SPEED
var _can_dash := true

var _dash_cooldown_timer: Timer
var _dash_fade_tween: Tween

func _init().("cat") -> void:
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
    $CatAnimator.face_right()

# Gets actions for the current frame.
#
# Stores these additional actions on the action map.
# {
#   start_dash,
# }
func _get_actions(delta: float) -> Dictionary:
    var actions := ._get_actions(delta)
    
    actions.start_dash = _can_dash and Input.is_action_just_pressed("dash")
    
    return actions

# Updates physics and player states in response to the current actions.
func _process_actions(actions: Dictionary) -> void:
    # Flip the horizontal direction of the animation according to which way the player is facing.
    if actions.pressed_left:
        $CatAnimator.face_left()
    if actions.pressed_right:
        $CatAnimator.face_right()
    
    # Cancel any horizontal velocity when bumping into a wall.
    if surface_state.is_touching_wall:
        # The move_and_slide system depends on maintained velocity always pushing the player into a
        # collision, otherwise it will eventually stop the collision. If we just zero this out,
        # is_on_wall() will give false negatives.
        velocity.x = MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION * \
                surface_state.toward_wall_sign

    if surface_state.is_grabbing_wall:
        _process_actions_while_on_wall(actions)
    elif surface_state.is_grabbing_floor:
        _process_actions_while_on_floor(actions)
    else:
        _process_actions_while_in_air(actions)
    
    _cap_velocity()
    
    _update_collision_mask()
    
    # We don't need to multiply velocity by delta because MoveAndSlide already takes delta time
    # into account.
    #warning-ignore:return_value_discarded
    move_and_slide(velocity, Utils.UP, false, 4, Utils.FLOOR_MAX_ANGLE)

#warning-ignore:unused_argument
func _process_actions_while_on_floor(actions: Dictionary) -> void:
    jump_count = 0
    is_ascending_from_jump = false
    
    # The move_and_slide system depends on some vertical gravity always pushing the player into
    # the floor. If we just zero this out, is_on_floor() will give false negatives.
    velocity.y = MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION
    
    # Horizontal movement.
    velocity.x += WALK_SPEED * surface_state.horizontal_movement_sign
    
    # Friction.
    var friction_offset := \
            Utils.get_floor_friction_coefficient(self) * FRICTION_MULTIPLIER * Utils.GRAVITY
    friction_offset = clamp(friction_offset, 0, abs(velocity.x))
    velocity.x += -sign(velocity.x) * friction_offset
    
    # Fall-through floor.
    if surface_state.is_falling_through_floors:
        # TODO: If we were already falling through the air, then we should instead maintain the previous velocity here.
        velocity.y = FALL_THROUGH_FLOOR_VELOCITY_BOOST
        
    # Jump.
    elif actions.just_pressed_jump:
        jump_count = 1
        is_ascending_from_jump = true
        velocity.y = JUMP_SPEED
    
    # Dash.
    if actions.start_dash:
        _start_dash(surface_state.horizontal_facing_sign)
    
    # Walking animation.
    if actions.pressed_left or actions.pressed_right:
        $CatAnimator.walk()
    else:
        $CatAnimator.rest()

func _process_actions_while_in_air(actions: Dictionary) -> void:
    # Horizontal movement.
    velocity.x += IN_AIR_HORIZONTAL_SPEED * surface_state.horizontal_movement_sign
    
    # We'll use this to descend faster than we ascend.
    if velocity.y > 0 or !actions.pressed_jump:
        is_ascending_from_jump = false
    
    # Gravity.
    var current_gravity: float
    if is_ascending_from_jump:
        # Make gravity stronger when falling. This creates a more satisfying jump.
        var gravity_multiplier := SLOW_DOUBLE_JUMP_ASCENT_GRAVITY_MULTIPLIER if jump_count > 1 \
                else SLOW_JUMP_ASCENT_GRAVITY_MULTIPLIER
        current_gravity = Utils.GRAVITY * gravity_multiplier
    else:
        current_gravity = Utils.GRAVITY
    velocity.y += actions.delta * current_gravity
    
    # Hit ceiling.
    if surface_state.is_touching_ceiling:
        is_ascending_from_jump = false
        velocity.y = MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION
    
    # Double jump.
    if actions.just_pressed_jump and jump_count < MAX_JUMP_CHAIN:
        jump_count += 1
        is_ascending_from_jump = true
        velocity.y = JUMP_SPEED
    
    # Dash.
    if actions.start_dash:
        _start_dash(surface_state.horizontal_facing_sign)
    
    # Animate.
    if velocity.y > 0:
        $CatAnimator.jump_descend()
    else:
        $CatAnimator.jump_ascend()

#warning-ignore:unused_argument
func _process_actions_while_on_wall(actions: Dictionary) -> void:
    jump_count = 0
    is_ascending_from_jump = false
    velocity.y = 0
    
    # Wall jump.
    if actions.just_pressed_jump:
        surface_state.is_grabbing_wall = false
        jump_count = 1
        is_ascending_from_jump = true
        
        velocity.y = JUMP_SPEED
        
        # Give a little boost to get the player away from the wall, so they can still be
        # pushing themselves into the wall when they start the jump.
        velocity.x = -surface_state.toward_wall_sign * IN_AIR_HORIZONTAL_SPEED * \
                WALL_JUMP_HORIZONTAL_MULTIPLIER
    
    # Fall off.
    elif surface_state.is_pressing_away_from_wall:
        surface_state.is_grabbing_wall = false
    
    # Start walking.
    elif surface_state.is_touching_floor and actions.pressed_down:
        surface_state.is_grabbing_wall = false
    
    # Climb up.
    elif actions.pressed_up:
        velocity.y = CLIMB_UP_SPEED
        $CatAnimator.climb_up()
    
    # Climb down.
    elif actions.pressed_down:
        velocity.y = CLIMB_DOWN_SPEED
        $CatAnimator.climb_down()
        
    # Rest.
    else:
        $CatAnimator.rest_on_wall()
    
    if actions.start_dash:
        _start_dash(-surface_state.toward_wall_sign)

func _cap_velocity() -> void:
    # Cap horizontal speed at a max value.
    velocity.x = clamp(velocity.x, -_current_max_horizontal_speed, _current_max_horizontal_speed)
    
    # Kill horizontal speed below a min value.
    if velocity.x > -MIN_HORIZONTAL_SPEED and velocity.x < MIN_HORIZONTAL_SPEED:
        velocity.x = 0
    
    # Cap vertical speed at a max value.
    velocity.y = clamp(velocity.y, -MAX_VERTICAL_SPEED, MAX_VERTICAL_SPEED)
    
    # Kill vertical speed below a min value.
    if velocity.y > -MIN_VERTICAL_SPEED and velocity.y < MIN_VERTICAL_SPEED:
        velocity.y = 0

# Update whether or not we should currently consider collisions with fall-through floors and
# walk-through walls.
func _update_collision_mask() -> void:
    set_collision_mask_bit(1, !surface_state.is_falling_through_floors)
    set_collision_mask_bit(2, surface_state.is_grabbing_walk_through_walls)

func _start_dash(horizontal_movement_sign: int) -> void:
    if !_can_dash:
        return
    
    _current_max_horizontal_speed = DEFAULT_MAX_HORIZONTAL_SPEED * DASH_SPEED_MULTIPLIER
    velocity.x = _current_max_horizontal_speed * horizontal_movement_sign
    
    velocity.y += DASH_VERTICAL_SPEED
    
    _dash_cooldown_timer.start(DASH_COOLDOWN)
    #warning-ignore:return_value_discarded
    _dash_fade_tween.reset_all()
    #warning-ignore:return_value_discarded
    _dash_fade_tween.interpolate_property(self, "_current_max_horizontal_speed", \
            DEFAULT_MAX_HORIZONTAL_SPEED * DASH_SPEED_MULTIPLIER, DEFAULT_MAX_HORIZONTAL_SPEED, \
            DASH_FADE_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN, \
            DASH_DURATION - DASH_FADE_DURATION)
    #warning-ignore:return_value_discarded
    _dash_fade_tween.start()
    
    if horizontal_movement_sign > 0:
        $CatAnimator.face_right()
    else:
        $CatAnimator.face_left()
    
func _dash_cooldown_finished() -> void:
    _can_dash = true
