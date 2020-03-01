extends PlayerActionHandler
class_name WallDashAction

const NAME := "WallDashAction"
const TYPE := SurfaceType.WALL
const PRIORITY := 160

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    if player.actions.start_dash:
        player.start_dash(-player.surface_state.toward_wall_sign)
        return true
    else:
        return false
