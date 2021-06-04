class_name WallClimbAction
extends PlayerActionHandler

const NAME := "WallClimbAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 150


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(player: Player) -> bool:
    if !player.processed_action(WallJumpAction.NAME) and \
            !player.processed_action(WallFallAction.NAME) and \
            !player.processed_action(WallWalkAction.NAME):
        if player.actions.pressed_up:
            player.velocity.y = player.movement_params.climb_up_speed
            return true
        elif player.actions.pressed_down:
            player.velocity.y = player.movement_params.climb_down_speed
            return true
    
    return false
