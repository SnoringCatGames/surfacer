extends PlayerActionHandler
class_name FloorWalkAction

const NAME := 'FloorWalkAction'
const TYPE := PlayerActionType.FLOOR
const PRIORITY := 220

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    # Horizontal movement.
    player.velocity.x += player.movement_params.walk_acceleration * \
            player.surface_state.horizontal_movement_sign
    
    # Friction.
    var friction_offset: float = Utils.get_floor_friction_coefficient(player) * \
            player.movement_params.friction_multiplier * player.movement_params.gravity_fast_fall
    friction_offset = clamp(friction_offset, 0, abs(player.velocity.x))
    player.velocity.x += -sign(player.velocity.x) * friction_offset

    return true
