extends KinematicBody2D

const UP = Vector2(0, -1)
const GRAVITY = 2000.0
const WALK_SPEED = 300
const CLIMB_SPEED = -200
const JUMP_SPEED = -800

var velocity = Vector2()

func _physics_process(delta):
    velocity.x = 0
        
    if is_on_ceiling():
        velocity.y = 0
    else:
        velocity.y += delta * GRAVITY

    get_input()

    # We don't need to multiply velocity by delta because MoveAndSlide already takes delta time into account.

    # The second parameter of move_and_slide is the normal pointing up.
    # In the case of a 2d platformer, in Godot upward is negative y, which translates to -1 as a normal.
    move_and_slide(velocity, UP)

func get_input():
    var just_pressed_space = Input.is_action_just_pressed("jump")
    var pressed_up = Input.is_action_pressed("move_up")
    var pressed_down = Input.is_action_pressed("move_down")
    var pressed_left = Input.is_action_pressed("move_left")
    var pressed_right = Input.is_action_pressed("move_right")

    if pressed_left:
        velocity.x = -WALK_SPEED
        $cat_animator.face_left()
    if pressed_right:
        velocity.x = WALK_SPEED
        $cat_animator.face_right()

    if is_on_floor():
        if just_pressed_space:
            velocity.y = JUMP_SPEED
        
        if pressed_left or pressed_right:
            $cat_animator.walk()
        else:
            $cat_animator.rest()
    else:
        if is_on_wall() and (pressed_left or pressed_right):
            if just_pressed_space:
                velocity.y = JUMP_SPEED
                if pressed_left:
                    velocity.x = WALK_SPEED * 7
                else:
                    velocity.x = -WALK_SPEED * 7
            else:
                velocity.y = 0

            if pressed_up:
                velocity.y = CLIMB_SPEED
                $cat_animator.climb_up()
            elif pressed_down:
                velocity.y = -CLIMB_SPEED
                $cat_animator.climb_down()
            else:
                $cat_animator.rest_on_wall()
        else:   
            $cat_animator.jump()
