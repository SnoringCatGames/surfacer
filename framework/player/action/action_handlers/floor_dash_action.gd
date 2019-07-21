extends PlayerActionHandler
class_name FloorDashAction

const NAME := 'FloorDashAction'
const TYPE := PlayerActionType.FLOOR
const PRIORITY := 250

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    if player.actions.start_dash:
        player.start_dash(player.surface_state.horizontal_facing_sign)
        return true
    else:
        return false
