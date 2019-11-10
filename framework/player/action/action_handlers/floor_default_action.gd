extends PlayerActionHandler
class_name FloorDefaultAction

const NAME := 'FloorDefaultAction'
const TYPE := PlayerActionSurfaceType.FLOOR
const PRIORITY := 210

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    player.jump_count = 0
    player.is_ascending_from_jump = false

    # The move_and_slide system depends on some vertical gravity always pushing the player into
    # the floor. If we just zero this out, is_on_floor() will give false negatives.
    player.velocity.y = player.movement_params.min_speed_to_maintain_vertical_collision

    return true
