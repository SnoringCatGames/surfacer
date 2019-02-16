extends KinematicBody2D

const UP = Vector2(0, -1)
const FLOOR_MAX_ANGLE = PI / 4
const GRAVITY = 5000.0
const SLOW_JUMP_ASCENT_GRAVITY_MULTIPLIER = .38
const SLOW_DOUBLE_JUMP_ASCENT_GRAVITY_MULTIPLIER = .68
const WALK_SPEED = 300
const FRICTION_MULTIPLIER = 0.01 # For calculating friction for walking
const IN_AIR_HORIZONTAL_SPEED = 300
const MAX_HORIZONTAL_SPEED = 400
const MIN_HORIZONTAL_SPEED = 50
const MAX_VERTICAL_SPEED = 4000
const MIN_VERTICAL_SPEED = 0
const CLIMB_UP_SPEED = -250
const CLIMB_DOWN_SPEED = 150
const JUMP_SPEED = -1000
const WALL_JUMP_HORIZONTAL_MULTIPLIER = 11
const MAX_JUMP_CHAIN = 2
const DASH_SPEED_MULTIPLIER = 4
const DASH_DELAY = 600 # In milliseconds

var velocity = Vector2()
var is_ascending_from_jump = false
var jump_count = 0

func _physics_process(delta):
    process_input(delta)

    # We don't need to multiply velocity by delta because MoveAndSlide already takes delta time
    # into account.
    move_and_slide(velocity, UP, false, 4, FLOOR_MAX_ANGLE)

func process_input(delta):
    var just_pressed_jump = Input.is_action_just_pressed("jump")
    var pressed_jump = Input.is_action_pressed("jump")
    var pressed_up = Input.is_action_pressed("move_up")
    var pressed_down = Input.is_action_pressed("move_down")
    var pressed_left = Input.is_action_pressed("move_left")
    var pressed_right = Input.is_action_pressed("move_right")
    var which_wall = get_which_wall_collided()
    
    # Detect wall grabs.
    var is_grabbing_wall = \
            (which_wall == "right" and pressed_right) or \
            (which_wall == "left" and pressed_left)
    
    # Flip the horizontal direction of the animation according to which way the player is facing.
    if pressed_left:
        $cat_animator.face_left()
    if pressed_right:
        $cat_animator.face_right()
    
    if is_on_wall():
        velocity.x = 0
    
    var horizontal_movement_sign
    if pressed_left:
        horizontal_movement_sign = -1
    elif pressed_right:
        horizontal_movement_sign = 1
    else:
        horizontal_movement_sign = 0
        
    # Horizontal movement.
    if is_on_floor():
        velocity.x += WALK_SPEED * horizontal_movement_sign
        
        # Friction.
        var friction_offset = get_floor_friction_coefficient() * FRICTION_MULTIPLIER * GRAVITY
        friction_offset = clamp(friction_offset, 0, abs(velocity.x))
        velocity.x += -sign(velocity.x) * friction_offset
    else:
        velocity.x += IN_AIR_HORIZONTAL_SPEED * horizontal_movement_sign

    # Gravity.
    if is_on_floor() or is_on_ceiling():
        is_ascending_from_jump = false
        # The move_and_slide system depends on some vertical gravity always pushing the player into
        # the floor. If we just zero this out, is_on_floor() will give false negatives.
        velocity.y = 15
    else:
        if velocity.y > 0 or !pressed_jump:
            is_ascending_from_jump = false
        
        # Make gravity stronger when falling. This creates a more satisfying jump.
        var currentGravity
        if is_ascending_from_jump:
            if jump_count > 1:
                currentGravity = GRAVITY * SLOW_DOUBLE_JUMP_ASCENT_GRAVITY_MULTIPLIER
            else:
                currentGravity = GRAVITY * SLOW_JUMP_ASCENT_GRAVITY_MULTIPLIER
        else:
            currentGravity = GRAVITY
        
        velocity.y += delta * currentGravity

    if is_grabbing_wall:
        jump_count = 0
        is_ascending_from_jump = false
        
        # Wall jump.
        if just_pressed_jump:
            jump_count = 1
            is_ascending_from_jump = true
            velocity.y = JUMP_SPEED
            
            # Give a little boost to get the player away from the wall, so they can still be
            # pushing themselves into the wall when they start the jump.
            if pressed_left:
                velocity.x = WALK_SPEED * WALL_JUMP_HORIZONTAL_MULTIPLIER
            else:
                velocity.x = -WALK_SPEED * WALL_JUMP_HORIZONTAL_MULTIPLIER
        else:
            velocity.y = 0

        # Climb.
        if pressed_up:
            velocity.y = CLIMB_UP_SPEED
            $cat_animator.climb_up()
        elif pressed_down:
            velocity.y = CLIMB_DOWN_SPEED
            $cat_animator.climb_down()
        else:
            $cat_animator.rest_on_wall()
    elif is_on_floor():
        jump_count = 0
        
        # Jump.
        if just_pressed_jump:
            jump_count = 1
            is_ascending_from_jump = true
            velocity.y = JUMP_SPEED
        
        # Walking animation.
        if pressed_left or pressed_right:
            $cat_animator.walk()
        else:
            $cat_animator.rest()
    else:
        $cat_animator.jump()
        
        # Double jump.
        if just_pressed_jump and jump_count < MAX_JUMP_CHAIN:
            jump_count += 1
            is_ascending_from_jump = true
            velocity.y = JUMP_SPEED
    
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