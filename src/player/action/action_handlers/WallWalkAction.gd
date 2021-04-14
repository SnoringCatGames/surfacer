class_name WallWalkAction
extends PlayerActionHandler

const NAME := "WallWalkAction"
const TYPE := SurfaceType.WALL
const PRIORITY := 140

func _init().(
        NAME,
        TYPE,
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    if !player.processed_action(WallJumpAction.NAME) and \
            !player.processed_action(WallFallAction.NAME) and \
            player.surface_state.is_touching_wall and \
            player.surface_state.is_touching_floor and \
            player.actions.pressed_down:
        player.surface_state.is_grabbing_wall = false
        return true
    else:
        return false
