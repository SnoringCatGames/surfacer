extends KinematicBody2D

const GRAVITY = 2000.0
const WALK_SPEED = 300
const JUMP_SPEED = -800

var velocity = Vector2()

func get_input():
    var jumping = Input.is_action_just_pressed("ui_up")
    var walking_left = Input.is_action_pressed("ui_left")
    var walking_right = Input.is_action_pressed("ui_right")

    if walking_left:
        velocity.x = -WALK_SPEED
    if walking_right:
        velocity.x = WALK_SPEED

    if walking_left:
        $cat_animator.walk_left()
    elif walking_right:
        $cat_animator.walk_right()
    else:
        $cat_animator.rest()
    
    if is_on_floor() and jumping:
        velocity.y = JUMP_SPEED

func _physics_process(delta):
    velocity.y += delta * GRAVITY
    velocity.x = 0

    get_input()

    # We don't need to multiply velocity by delta because MoveAndSlide already takes delta time into account.

    # The second parameter of move_and_slide is the normal pointing up.
    # In the case of a 2d platformer, in Godot upward is negative y, which translates to -1 as a normal.
    move_and_slide(velocity, Vector2(0, -1))
