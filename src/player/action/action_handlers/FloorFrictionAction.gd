class_name FloorFrictionAction
extends PlayerActionHandler

const NAME := "FloorFrictionAction"
const TYPE := SurfaceType.FLOOR
const PRIORITY := 250

func _init().(
        NAME,
        TYPE,
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    if !player.processed_action(FloorJumpAction.NAME):
        # Friction.
        var friction_offset: float = \
                Gs.utils.get_floor_friction_multiplier(player) * \
                player.movement_params.friction_coefficient * \
                player.movement_params.gravity_fast_fall
        friction_offset = clamp(friction_offset, 0, abs(player.velocity.x))
        player.velocity.x += -sign(player.velocity.x) * friction_offset
        
        return true
    else:
        return false
