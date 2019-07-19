extends PlayerAction
class_name FloorJumpAction

const NAME := 'FloorJumpAction'
const TYPE := PlayerActionType.FLOOR
const PRIORITY := 230

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    if !player.processed_action(FloorFallThroughAction.NAME) and \
            player.actions.just_pressed_jump:
        player.jump_count = 1
        player.is_ascending_from_jump = true
        player.velocity.y = player.movement_params.jump_boost

        return true
    else:
        return false
