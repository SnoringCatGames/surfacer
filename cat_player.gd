extends KinematicBody2D

const UP = Vector2(0, -1)
const FLOOR_MAX_ANGLE = PI / 4
const GRAVITY = 5000.0
const SLOW_JUMP_ASCENT_GRAVITY_MULTIPLIER = .38
const SLOW_DOUBLE_JUMP_ASCENT_GRAVITY_MULTIPLIER = .68
const WALK_SPEED = 350
const FRICTION_MULTIPLIER = 0.01 # For calculating friction for walking
const IN_AIR_HORIZONTAL_SPEED = 300
const MAX_HORIZONTAL_SPEED = 400
const MIN_HORIZONTAL_SPEED = 50
const MAX_VERTICAL_SPEED = 4000
const MIN_VERTICAL_SPEED = 0
const CLIMB_UP_SPEED = -350
const CLIMB_DOWN_SPEED = 150
const JUMP_SPEED = -1000
const WALL_JUMP_HORIZONTAL_MULTIPLIER = .5
const MAX_JUMP_CHAIN = 2
const DASH_SPEED_MULTIPLIER = 4
const DASH_DELAY = 600 # In milliseconds
const MIN_VERTICAL_SPEED_FOR_FLOOR_COLLISIONS = 15

var velocity = Vector2()
var is_ascending_from_jump = false
var jump_count = 0
var is_grabbing_wall = false

func _physics_process(delta):
    process_input(delta)

    # We don't need to multiply velocity by delta because MoveAndSlide already takes delta time
    # into account.
    move_and_slide(velocity, UP, false, 4, FLOOR_MAX_ANGLE)

func process_input(delta):
    var actions = get_current_actions()
    
    # Flip the horizontal direction of the animation according to which way the player is facing.
    if actions.pressed_left:
        $cat_animator.face_left()
    if actions.pressed_right:
        $cat_animator.face_right()
    
    # Detect wall grabs.
    if !is_on_wall():
        is_grabbing_wall = false
    elif actions.pressing_into_wall:
        is_grabbing_wall = true
    
    # Cancel any horizontal velocity when bumping into a wall.
    if is_on_wall():
        velocity.x = 0

    if is_grabbing_wall:
        process_input_while_on_wall(delta, actions)
    elif is_on_floor():
        process_input_while_on_floor(delta, actions)
    else:
        process_input_while_in_air(delta, actions)
    
    cap_velocity()

func get_current_actions():
    var actions = {
        just_pressed_jump = Input.is_action_just_pressed("jump"),
        pressed_jump = Input.is_action_pressed("jump"),
        pressed_up = Input.is_action_pressed("move_up"),
        pressed_down = Input.is_action_pressed("move_down"),
        pressed_left = Input.is_action_pressed("move_left"),
        pressed_right = Input.is_action_pressed("move_right"),
        which_wall = get_which_wall_collided(),
        pressing_into_wall = false,
        pressing_away_from_wall = false,
        horizontal_movement_sign = 0
    }
 
    actions.pressing_into_wall = \
        (actions.which_wall == "right" and actions.pressed_right) or \
        (actions.which_wall == "left" and actions.pressed_left)
    actions.pressing_away_from_wall = \
        (actions.which_wall == "right" and actions.pressed_left) or \
        (actions.which_wall == "left" and actions.pressed_right)
    
    if actions.pressed_left:
        actions.horizontal_movement_sign = -1
    elif actions.pressed_right:
        actions.horizontal_movement_sign = 1
        
    return actions

func process_input_while_on_floor(delta, actions):
    jump_count = 0
    is_ascending_from_jump = false
    
    # The move_and_slide system depends on some vertical gravity always pushing the player into
    # the floor. If we just zero this out, is_on_floor() will give false negatives.
    velocity.y = MIN_VERTICAL_SPEED_FOR_FLOOR_COLLISIONS
    
    # Horizontal movement.
    velocity.x += WALK_SPEED * actions.horizontal_movement_sign
    
    # Friction.
    var friction_offset = get_floor_friction_coefficient() * FRICTION_MULTIPLIER * GRAVITY
    friction_offset = clamp(friction_offset, 0, abs(velocity.x))
    velocity.x += -sign(velocity.x) * friction_offset
    
    # Jump.
    if actions.just_pressed_jump:
        jump_count = 1
        is_ascending_from_jump = true
        velocity.y = JUMP_SPEED
    
    # Walking animation.
    if actions.pressed_left or actions.pressed_right:
        $cat_animator.walk()
    else:
        $cat_animator.rest()

func process_input_while_in_air(delta, actions):
    # Horizontal movement.
    velocity.x += IN_AIR_HORIZONTAL_SPEED * actions.horizontal_movement_sign
    
    # We'll use this to descend faster than we ascend.
    if velocity.y > 0 or !actions.pressed_jump:
        is_ascending_from_jump = false
    
    # Gravity.
    var current_gravity
    if is_ascending_from_jump:
        # Make gravity stronger when falling. This creates a more satisfying jump.
        var gravity_multiplier = SLOW_DOUBLE_JUMP_ASCENT_GRAVITY_MULTIPLIER if jump_count > 1 \
                else SLOW_JUMP_ASCENT_GRAVITY_MULTIPLIER
        current_gravity = GRAVITY * gravity_multiplier
    else:
        current_gravity = GRAVITY
    velocity.y += delta * current_gravity
    
    # Hit ceiling.
    if is_on_ceiling():
        is_ascending_from_jump = false
        velocity.y = MIN_VERTICAL_SPEED_FOR_FLOOR_COLLISIONS
    
    # Double jump.
    if actions.just_pressed_jump and jump_count < MAX_JUMP_CHAIN:
        jump_count += 1
        is_ascending_from_jump = true
        velocity.y = JUMP_SPEED
    
    # Animate.
    if velocity.y > 0:
        $cat_animator.jump_descend()
    else:
        $cat_animator.jump_ascend()

func process_input_while_on_wall(delta, actions):
    jump_count = 0
    is_ascending_from_jump = false
    velocity.y = 0
    
    # Wall jump.
    if actions.just_pressed_jump:
        is_grabbing_wall = false
        jump_count = 1
        is_ascending_from_jump = true
        
        velocity.y = JUMP_SPEED
        
        # Give a little boost to get the player away from the wall, so they can still be
        # pushing themselves into the wall when they start the jump.
        var wall_sign = -1 if actions.which_wall == "right" else 1;
        velocity.x = wall_sign * IN_AIR_HORIZONTAL_SPEED * WALL_JUMP_HORIZONTAL_MULTIPLIER
    
    # Fall off.
    elif actions.pressing_away_from_wall:
        is_grabbing_wall = false
    
    # Start walking.
    elif is_on_floor() and actions.pressed_down:
        is_grabbing_wall = false
    
    # Climb up.
    elif actions.pressed_up:
        velocity.y = CLIMB_UP_SPEED
        $cat_animator.climb_up()
    
    # Climb down.
    elif actions.pressed_down:
        velocity.y = CLIMB_DOWN_SPEED
        $cat_animator.climb_down()
        
    # Rest.
    else:
        $cat_animator.rest_on_wall()

func cap_velocity():
    # Cap horizontal speed at a max value.
    velocity.x = clamp(velocity.x, -MAX_HORIZONTAL_SPEED, MAX_HORIZONTAL_SPEED)
    
    # Kill horizontal speed below a min value.
    if velocity.x > -MIN_HORIZONTAL_SPEED and velocity.x < MIN_HORIZONTAL_SPEED:
        velocity.x = 0
    
    # Cap vertical speed at a max value.
    velocity.y = clamp(velocity.y, -MAX_VERTICAL_SPEED, MAX_VERTICAL_SPEED)
    
    # Kill vertical speed below a min value.
    if velocity.y > -MIN_VERTICAL_SPEED and velocity.y < MIN_VERTICAL_SPEED:
        velocity.y = 0

func get_which_wall_collided():
    if is_on_wall():
        for i in range(get_slide_count()):
            var collision = get_slide_collision(i)
            if collision.normal.x > 0:
                return "left"
            elif collision.normal.x < 0:
                return "right"
    return "none"

func get_floor_collision():
    if is_on_floor():
        for i in range(get_slide_count()):
            var collision = get_slide_collision(i)
            if abs(collision.normal.angle_to(UP)) <= FLOOR_MAX_ANGLE:
                return collision
    return null

func get_floor_friction_coefficient():
    var collision = get_floor_collision()
    if collision != null and collision.collider.collision_friction != null:
        return collision.collider.collision_friction
    return 0