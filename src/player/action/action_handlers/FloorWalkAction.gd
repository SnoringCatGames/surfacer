class_name FloorWalkAction
extends PlayerActionHandler


const NAME := "FloorWalkAction"
const TYPE := SurfaceType.FLOOR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 240


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(player: Player) -> bool:
    if !player.processed_action(FloorJumpAction.NAME):
        # Horizontal movement.
        player.velocity.x += \
                player.movement_params.walk_acceleration * \
                player.actions.delta_scaled * \
                player.surface_state.horizontal_acceleration_sign
        
        return true
    else:
        return false
