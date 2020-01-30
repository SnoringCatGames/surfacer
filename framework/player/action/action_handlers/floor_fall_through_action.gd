extends PlayerActionHandler
class_name FloorFallThroughAction

const NAME := 'FloorFallThroughAction'
const TYPE := PlayerActionSurfaceType.FLOOR
const PRIORITY := 220

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    if player.surface_state.is_falling_through_floors:
        # TODO: If we were already falling through the air, then we should instead maintain the previous velocity here.
        player.velocity.y = player.movement_params.fall_through_floor_velocity_boost
        return true
    else:
        return false
