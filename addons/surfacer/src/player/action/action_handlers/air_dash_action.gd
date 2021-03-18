extends PlayerActionHandler
class_name AirDashAction

const NAME := "AirDashAction"
const TYPE := SurfaceType.AIR
const PRIORITY := 330

func _init().( \
        NAME, \
        TYPE, \
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    if player.actions.start_dash:
        player.start_dash(player.surface_state.horizontal_facing_sign)
        return true
    else:
        return false
