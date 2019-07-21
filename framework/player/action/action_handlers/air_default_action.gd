extends PlayerActionHandler
class_name AirDefaultAction

const NAME := 'AirDefaultAction'
const TYPE := PlayerActionType.AIR
const PRIORITY := 310

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    # If the player falls off a wall or ledge, then that's considered the first jump.
    player.jump_count = max(player.jump_count, 1)
    
    var is_first_jump: bool = player.jump_count == 1
    
    player.velocity = update_velocity_in_air(player.velocity, \
            player.actions.delta, player.actions.pressed_jump, is_first_jump, \
            player.surface_state.horizontal_movement_sign, player.movement_params)
    
    # Hit ceiling.
    if player.surface_state.is_touching_ceiling:
        player.is_ascending_from_jump = false
        player.velocity.y = -player.movement_params.min_speed_to_maintain_vertical_collision
    
    return true

static func update_velocity_in_air( \
        velocity: Vector2, delta: float, is_pressing_jump: bool, is_first_jump: bool, \
        horizontal_movement_sign: int, movement_params: MovementParams) -> Vector2:
    var is_ascending_from_jump := velocity.y < 0 and is_pressing_jump
    
    # Make gravity stronger when falling. This creates a more satisfying jump.
    # Similarly, make gravity stronger for double jumps.
    var gravity_multiplier := 1.0 if !is_ascending_from_jump else \
            (movement_params.slow_ascent_gravity_multiplier if is_first_jump \
                    else movement_params.ascent_double_jump_gravity_multiplier)
    
    # Vertical movement.
    velocity.y += delta * movement_params.gravity_fast_fall * gravity_multiplier
    
    # Horizontal movement.
    velocity.x += delta * movement_params.in_air_horizontal_acceleration * horizontal_movement_sign
    
    return velocity
