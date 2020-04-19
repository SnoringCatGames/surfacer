extends PlayerActionHandler
class_name FloorWalkAction

const NAME := "FloorWalkAction"
const TYPE := SurfaceType.FLOOR
const PRIORITY := 240

func _init().( \
        NAME, \
        TYPE, \
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    if !player.processed_action(FloorJumpAction.NAME):
        # Horizontal movement.
        player.velocity.x += player.movement_params.walk_acceleration * \
                player.surface_state.horizontal_acceleration_sign
        
        return true
    else:
        return false
