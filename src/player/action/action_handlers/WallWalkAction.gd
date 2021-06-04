class_name WallWalkAction
extends PlayerActionHandler


const NAME := "WallWalkAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 140


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(player: Player) -> bool:
    if !player.processed_action(WallJumpAction.NAME) and \
            !player.processed_action(WallFallAction.NAME) and \
            player.surface_state.is_touching_wall and \
            player.surface_state.is_touching_floor and \
            player.actions.pressed_down:
        player.release_wall()
        return true
    else:
        return false
