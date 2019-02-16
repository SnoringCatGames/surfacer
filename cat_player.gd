extends KinematicBody2D

const UP = Vector2(0, -1)
const GRAVITY = 5000.0
const SLOW_JUMP_ASCENT_GRAVITY_MULTIPLIER = .38
const WALK_SPEED = 300
const CLIMB_UP_SPEED = -250
const CLIMB_DOWN_SPEED = 150
const JUMP_SPEED = -1000
const WALL_JUMP_HORIZONTAL_MULTIPLIER = 9

var velocity = Vector2()
var is_ascending_from_jump = false

func _physics_process(delta):
    velocity.x = 0
    
    process_input(delta)

    # We don't need to multiply velocity by delta because MoveAndSlide already takes delta time
    # into account.
    move_and_slide(velocity, UP)

func process_input(delta):
    var just_pressed_jump = Input.is_action_just_pressed("jump")
    var pressed_jump = Input.is_action_pressed("jump")
    var pressed_up = Input.is_action_pressed("move_up")
    var pressed_down = Input.is_action_pressed("move_down")
    var pressed_left = Input.is_action_pressed("move_left")
    var pressed_right = Input.is_action_pressed("move_right")
    
    # Horizontal movement (on ground or in air).
    if pressed_left:
        velocity.x = -WALK_SPEED
        $cat_animator.face_left()
    if pressed_right:
        velocity.x = WALK_SPEED
        $cat_animator.face_right()

    # Gravity.
    if is_on_floor() or is_on_ceiling():
        is_ascending_from_jump = false
        # The move_and_slide system depends on some vertical gravity always pushing the player into
        # the floor. If we just zero this out, is_on_floor() will give false negatives.
        velocity.y = 0.8
    else:
        if velocity.y > 0 or !pressed_jump:
            is_ascending_from_jump = false
        
        # Make gravity stronger when falling. This creates a more satisfying jump.
        var currentGravity
        if is_ascending_from_jump:
            currentGravity = GRAVITY * SLOW_JUMP_ASCENT_GRAVITY_MULTIPLIER
        else:
            currentGravity = GRAVITY
        
        velocity.y += delta * currentGravity

    if is_on_floor():
        # Jump.
        if just_pressed_jump:
            is_ascending_from_jump = true
            velocity.y = JUMP_SPEED
        
        # Walking animation.
        if pressed_left or pressed_right:
            $cat_animator.walk()
        else:
            $cat_animator.rest()
    else:
        # Wall grab.
        if is_on_wall() and (pressed_left or pressed_right):
            is_ascending_from_jump = false
            
            # Wall jump.
            if just_pressed_jump:
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
        else:
            $cat_animator.jump()

func get_which_wall_collided():
    for i in range(get_slide_count()):
        var collision = get_slide_collision(i)
        if collision.normal.x > 0:
            return "left"
        elif collision.normal.x < 0:
            return "right"
    return "none"
