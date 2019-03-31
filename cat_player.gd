extends KinematicBody2D
class_name CatPlayer

const SLOW_JUMP_ASCENT_GRAVITY_MULTIPLIER := .38
const SLOW_DOUBLE_JUMP_ASCENT_GRAVITY_MULTIPLIER := .68
const WALK_SPEED := 350
const FRICTION_MULTIPLIER := 0.01 # For calculating friction for walking
const IN_AIR_HORIZONTAL_SPEED := 300
const DEFAULT_MAX_HORIZONTAL_SPEED := 400
const MIN_HORIZONTAL_SPEED := 50
const MAX_VERTICAL_SPEED := 4000
const MIN_VERTICAL_SPEED := 0
const CLIMB_UP_SPEED := -350
const CLIMB_DOWN_SPEED := 150
const JUMP_SPEED := -1000
const WALL_JUMP_HORIZONTAL_MULTIPLIER := .5
const MAX_JUMP_CHAIN := 2
const DASH_SPEED_MULTIPLIER := 4
const DASH_VERTICAL_SPEED := -400
const DASH_DURATION := .3
const DASH_FADE_DURATION := .1
const DASH_COOLDOWN := 1
const FALL_THROUGH_FLOOR_VELOCITY_BOOST := 100
const MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION := 15
const MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION := MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION * 4

var velocity := Vector2()
var horizontal_facing_sign := -1
var is_ascending_from_jump := false
var jump_count := 0
var is_grabbing_wall := false
var is_falling_through_floors := false
var is_grabbing_walk_through_walls := false

var _toward_wall_collision_sign := 0;
var _current_max_horizontal_speed := DEFAULT_MAX_HORIZONTAL_SPEED
var _can_dash := true

var _dash_cooldown_timer: Timer
var _dash_fade_tween: Tween

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
    horizontal_facing_sign = 1
    $CatAnimator.face_right()

func _physics_process(delta: float) -> void:
    _process_input(delta)

    # We don't need to multiply velocity by delta because MoveAndSlide already takes delta time
    # into account.
    #warning-ignore:return_value_discarded
    move_and_slide(velocity, Global.UP, false, 4, Global.FLOOR_MAX_ANGLE)

func _process_input(delta: float) -> void:
    var actions := _get_current_actions()
    
    # Flip the horizontal direction of the animation according to which way the player is facing.
    if actions.pressed_left:
        horizontal_facing_sign = -1
        $CatAnimator.face_left()
    if actions.pressed_right:
        horizontal_facing_sign = 1
        $CatAnimator.face_right()
    
    # Detect wall grabs.
    if !is_on_wall():
        is_grabbing_wall = false
    elif actions.triggering_wall_grab:
        is_grabbing_wall = true
        
    # Calculate the sign of a collding wall's direction.
    _toward_wall_collision_sign = (0 if !is_on_wall() else \
            (1 if actions.which_wall == "right" else -1))
    
    # Cancel any horizontal velocity when bumping into a wall.
    if is_on_wall():
        # The move_and_slide system depends on maintained velocity always pushing the player into a
        # collision, otherwise it will eventually stop the collision. If we just zero this out,
        # is_on_wall() will give false negatives.
        velocity.x = MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION * _toward_wall_collision_sign

    if is_grabbing_wall:
        _process_input_while_on_wall(delta, actions)
    elif is_on_floor():
        _process_input_while_on_floor(delta, actions)
    else:
        _process_input_while_in_air(delta, actions)
    
    _cap_velocity()
    
    _update_collision_mask()

func _get_current_actions() -> Dictionary:
    var actions := {
        just_pressed_jump = Input.is_action_just_pressed("jump"),
        pressed_jump = Input.is_action_pressed("jump"),
        pressed_up = Input.is_action_pressed("move_up"),
        pressed_down = Input.is_action_pressed("move_down"),
        pressed_left = Input.is_action_pressed("move_left"),
        pressed_right = Input.is_action_pressed("move_right"),
        which_wall = _get_which_wall_collided(),
        horizontal_movement_sign = 0,
        facing_wall = false,
        pressing_into_wall = false,
        pressing_away_from_wall = false,
        triggering_wall_grab = false,
        start_dash = _can_dash and Input.is_action_just_pressed("dash"),
        start_fall_through = false
    }
    
    if actions.pressed_left:
        actions.horizontal_movement_sign = -1
    elif actions.pressed_right:
        actions.horizontal_movement_sign = 1
     
    actions.facing_wall = \
        (actions.which_wall == "right" and horizontal_facing_sign > 0) or \
        (actions.which_wall == "left" and horizontal_facing_sign < 0)
    actions.pressing_into_wall = \
        (actions.which_wall == "right" and actions.pressed_right) or \
        (actions.which_wall == "left" and actions.pressed_left)
    actions.pressing_away_from_wall = \
        (actions.which_wall == "right" and actions.pressed_left) or \
        (actions.which_wall == "left" and actions.pressed_right)
    
    var facing_into_wall_and_pressing_up: bool = actions.pressed_up and (actions.facing_wall or actions.pressing_into_wall)
    actions.triggering_wall_grab = actions.pressing_into_wall or facing_into_wall_and_pressing_up
    
    actions.start_fall_through = actions.pressed_down and actions.just_pressed_jump
    
    return actions

#warning-ignore:unused_argument
func _process_input_while_on_floor(delta: float, actions: Dictionary) -> void:
    jump_count = 0
    is_ascending_from_jump = false
    is_falling_through_floors = false
    
    # Whether we should grab onto walk-through walls.
    is_grabbing_walk_through_walls = actions.pressed_up
    
    # The move_and_slide system depends on some vertical gravity always pushing the player into
    # the floor. If we just zero this out, is_on_floor() will give false negatives.
    velocity.y = MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION
    
    # Horizontal movement.
    velocity.x += WALK_SPEED * actions.horizontal_movement_sign
    
    # Friction.
    var friction_offset := _get_floor_friction_coefficient() * FRICTION_MULTIPLIER * Global.GRAVITY
    friction_offset = clamp(friction_offset, 0, abs(velocity.x))
    velocity.x += -sign(velocity.x) * friction_offset
    
    # Fall-through floor.
    if actions.start_fall_through:
        is_falling_through_floors = true
        velocity.y = FALL_THROUGH_FLOOR_VELOCITY_BOOST
        
    # Jump.
    elif actions.just_pressed_jump:
        jump_count = 1
        is_ascending_from_jump = true
        velocity.y = JUMP_SPEED
    
    # Dash.
    if actions.start_dash:
        _start_dash(horizontal_facing_sign)
    
    # Walking animation.
    if actions.pressed_left or actions.pressed_right:
        $CatAnimator.walk()
    else:
        $CatAnimator.rest()

func _process_input_while_in_air(delta: float, actions: Dictionary) -> void:
    # Whether we should fall through fall-through floors.
    is_falling_through_floors = actions.pressed_down
    
    # Whether we should grab onto walk-through walls.
    is_grabbing_walk_through_walls = actions.pressed_up
    
    # Horizontal movement.
    velocity.x += IN_AIR_HORIZONTAL_SPEED * actions.horizontal_movement_sign
    
    # We'll use this to descend faster than we ascend.
    if velocity.y > 0 or !actions.pressed_jump:
        is_ascending_from_jump = false
    
    # Gravity.
    var current_gravity: float
    if is_ascending_from_jump:
        # Make gravity stronger when falling. This creates a more satisfying jump.
        var gravity_multiplier := SLOW_DOUBLE_JUMP_ASCENT_GRAVITY_MULTIPLIER if jump_count > 1 \
                else SLOW_JUMP_ASCENT_GRAVITY_MULTIPLIER
        current_gravity = Global.GRAVITY * gravity_multiplier
    else:
        current_gravity = Global.GRAVITY
    velocity.y += delta * current_gravity
    
    # Hit ceiling.
    if is_on_ceiling():
        is_ascending_from_jump = false
        velocity.y = MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION
    
    # Double jump.
    if actions.just_pressed_jump and jump_count < MAX_JUMP_CHAIN:
        jump_count += 1
        is_ascending_from_jump = true
        velocity.y = JUMP_SPEED
    
    # Dash.
    if actions.start_dash:
        _start_dash(horizontal_facing_sign)
    
    # Animate.
    if velocity.y > 0:
        $CatAnimator.jump_descend()
    else:
        $CatAnimator.jump_ascend()

#warning-ignore:unused_argument
func _process_input_while_on_wall(delta: float, actions: Dictionary) -> void:
    jump_count = 0
    is_ascending_from_jump = false
    is_grabbing_walk_through_walls = true
    velocity.y = 0
    
    # Whether we should fall through fall-through floors.
    is_falling_through_floors = actions.pressed_down
    
    # Wall jump.
    if actions.just_pressed_jump:
        is_grabbing_wall = false
        jump_count = 1
        is_ascending_from_jump = true
        
        velocity.y = JUMP_SPEED
        
        # Give a little boost to get the player away from the wall, so they can still be
        # pushing themselves into the wall when they start the jump.
        velocity.x = -_toward_wall_collision_sign * IN_AIR_HORIZONTAL_SPEED * WALL_JUMP_HORIZONTAL_MULTIPLIER
    
    # Fall off.
    elif actions.pressing_away_from_wall:
        is_grabbing_wall = false
    
    # Start walking.
    elif is_on_floor() and actions.pressed_down:
        is_grabbing_wall = false
    
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
        _start_dash(-_toward_wall_collision_sign)

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
    set_collision_mask_bit(1, !is_falling_through_floors)
    set_collision_mask_bit(2, is_grabbing_walk_through_walls)

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

func _get_which_wall_collided() -> String:
    if is_on_wall():
        for i in range(get_slide_count()):
            var collision := get_slide_collision(i)
            if collision.normal.x > 0:
                return "left"
            elif collision.normal.x < 0:
                return "right"
    return "none"

func _get_floor_collision() -> KinematicCollision2D:
    if is_on_floor():
        for i in range(get_slide_count()):
            var collision := get_slide_collision(i)
            if abs(collision.normal.angle_to(Global.UP)) <= Global.FLOOR_MAX_ANGLE:
                return collision
    return null

func _get_floor_friction_coefficient() -> float:
    var collision := _get_floor_collision()
    # Collision friction is a property of the TileMap node.
    if collision != null and collision.collider.collision_friction != null:
        return collision.collider.collision_friction
    return 0.0
