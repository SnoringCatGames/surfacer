class_name WallDefaultAction
extends PlayerActionHandler

const NAME := "WallDefaultAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 110

func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    player.jump_count = 0
    player.is_rising_from_jump = false
    player.velocity.y = 0.0

    return true
