class_name WallJumpAction
extends PlayerActionHandler

const NAME := "WallJumpAction"
const TYPE := SurfaceType.WALL
const PRIORITY := 120

func _init().(
        NAME,
        TYPE,
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    if player.actions.just_pressed_jump:
        player.surface_state.is_grabbing_wall = false
        player.jump_count = 1
        player.just_triggered_jump = true
        player.is_rising_from_jump = true
        
        player.velocity.y = player.movement_params.jump_boost
        
        # Give a little boost to get the player away from the wall, so they can
        # still be pushing themselves into the wall when they start the jump.
        player.velocity.x = \
                -player.surface_state.toward_wall_sign * \
                player.movement_params.wall_jump_horizontal_boost
        
        return true
    else:
        return false
