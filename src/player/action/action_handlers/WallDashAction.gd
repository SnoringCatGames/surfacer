class_name WallDashAction
extends PlayerActionHandler

const NAME := "WallDashAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 160


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(player: Player) -> bool:
    if player.actions.start_dash:
        player.start_dash(-player.surface_state.toward_wall_sign)
        return true
    else:
        return false
