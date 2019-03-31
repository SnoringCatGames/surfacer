extends KinematicBody2D
class_name Squirrel

const MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION := 15
const MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION := MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION * 4

var velocity := Vector2()

func _physics_process(delta: float) -> void:
    # The move_and_slide system depends on some vertical gravity always pushing the player into
    # the floor. If we just zero this out, is_on_floor() will give false negatives.
    velocity.y = MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION
    
    velocity.x = 0

    # We don't need to multiply velocity by delta because MoveAndSlide already takes delta time
    # into account.
    move_and_slide(velocity, Global.UP, false, 4, Global.FLOOR_MAX_ANGLE)
