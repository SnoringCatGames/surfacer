extends PlayerActionHandler
class_name AirDefaultAction

const NAME := 'AirDefaultAction'
const TYPE := PlayerActionSurfaceType.AIR
const PRIORITY := 310

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    # If the player falls off a wall or ledge, then that's considered the first jump.
    player.jump_count = max(player.jump_count, 1)
    
    var is_first_jump: bool = player.jump_count == 1
    
    player.velocity = MovementUtils.update_velocity_in_air(player.velocity, \
            player.actions.delta, player.actions.pressed_jump, is_first_jump, \
            player.surface_state.horizontal_acceleration_sign, player.movement_params)
    
    # Hit ceiling.
    if player.surface_state.is_touching_ceiling:
        player.is_ascending_from_jump = false
        player.velocity.y = player.movement_params.min_speed_to_maintain_vertical_collision
    
    return true
