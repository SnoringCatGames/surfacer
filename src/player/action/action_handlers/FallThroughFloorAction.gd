class_name FloorFallThroughAction
extends PlayerActionHandler

const NAME := "FloorFallThroughAction"
const TYPE := SurfaceType.FLOOR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 220


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(player: Player) -> bool:
    if player.surface_state.is_falling_through_floors:
        # TODO: If we were already falling through the air, then we should
        #       instead maintain the previous velocity here.
        player.velocity.y = \
                player.movement_params.fall_through_floor_velocity_boost
        return true
    else:
        return false
