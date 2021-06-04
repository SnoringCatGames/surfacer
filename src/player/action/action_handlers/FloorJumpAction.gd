class_name FloorJumpAction
extends PlayerActionHandler

const NAME := "FloorJumpAction"
const TYPE := SurfaceType.FLOOR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 230


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(player: Player) -> bool:
    if !player.processed_action(FloorFallThroughAction.NAME) and \
            player.actions.just_pressed_jump:
        player.jump_count = 1
        player.just_triggered_jump = true
        player.is_rising_from_jump = true
        player.velocity.y = player.movement_params.jump_boost

        return true
    else:
        return false
