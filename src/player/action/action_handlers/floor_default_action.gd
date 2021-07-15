class_name FloorDefaultAction
extends PlayerActionHandler


const NAME := "FloorDefaultAction"
const TYPE := SurfaceType.FLOOR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 210


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(player) -> bool:
    player.jump_count = 0
    player.is_rising_from_jump = false

    # The move_and_slide system depends on some vertical gravity always pushing
    # the player into the floor. If we just zero this out, is_on_floor() will
    # give false negatives.
    player.velocity.y = \
            PlayerActionHandler.MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION / \
            Sc.time.get_combined_scale()

    return true
