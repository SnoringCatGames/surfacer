extends PlayerActionHandler
class_name AirDefaultAction

const NAME := "AirDefaultAction"
const TYPE := SurfaceType.AIR
const PRIORITY := 310

func _init().( \
        NAME, \
        TYPE, \
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    # If the player falls off a wall or ledge, then that's considered the first jump.
    player.jump_count = max(player.jump_count, 1)
    
    var is_first_jump: bool = player.jump_count == 1
    
    # If we just fell off the bottom of a wall, cancel any velocity toward that wall.
    if player.surface_state.just_entered_air and \
            ((player.surface_state.previous_grabbed_surface.side == SurfaceSide.LEFT_WALL and \
                    player.velocity.x < 0.0) or \
            (player.surface_state.previous_grabbed_surface.side == SurfaceSide.RIGHT_WALL and \
                    player.velocity.x > 0.0)):
        player.velocity.x = 0.0
    
    player.velocity = MovementUtils.update_velocity_in_air( \
            player.velocity, \
            player.actions.delta_sec, \
            player.actions.pressed_jump, \
            is_first_jump, \
            player.surface_state.horizontal_acceleration_sign, \
            player.movement_params)
    
    # Hit ceiling.
    if player.surface_state.is_touching_ceiling:
        player.is_rising_from_jump = false
        player.velocity.y = PlayerActionHandler.MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION
    
    return true
