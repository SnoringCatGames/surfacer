extends PlayerActionHandler
class_name WallFallAction

const NAME := "WallFallAction"
const TYPE := SurfaceType.WALL
const PRIORITY := 130

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    if !player.processed_action(WallJumpAction.NAME) and \
            player.surface_state.is_pressing_away_from_wall:
        player.surface_state.is_grabbing_wall = false
        return true
    else:
        return false
