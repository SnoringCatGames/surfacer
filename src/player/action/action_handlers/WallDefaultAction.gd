class_name WallDefaultAction
extends PlayerActionHandler

const NAME := "WallDefaultAction"
const TYPE := SurfaceType.WALL
const PRIORITY := 110

func _init().(
        NAME,
        TYPE,
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    player.jump_count = 0
    player.is_rising_from_jump = false
    player.velocity.y = 0.0

    return true
