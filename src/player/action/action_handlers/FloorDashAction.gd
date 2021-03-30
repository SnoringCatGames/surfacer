class_name FloorDashAction
extends PlayerActionHandler

const NAME := "FloorDashAction"
const TYPE := SurfaceType.FLOOR
const PRIORITY := 260

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
