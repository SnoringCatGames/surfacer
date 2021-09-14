class_name AirDefaultAction
extends CharacterActionHandler


const NAME := "AirDefaultAction"
const TYPE := SurfaceType.AIR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 410

const BOUNCE_OFF_CEILING_VELOCITY := 15.0


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    # If the character falls off a wall or ledge, then that's considered the
    # first jump.
    character.jump_count = max(character.jump_count, 1)
    
    var is_first_jump: bool = character.jump_count == 1
    
    # If we just fell off the bottom of a wall, cancel any velocity toward that
    # wall.
    if character.surface_state.just_entered_air and \
            ((character.surface_state.previous_grabbed_surface.side == \
                    SurfaceSide.LEFT_WALL and \
                    character.velocity.x < 0.0) or \
            (character.surface_state.previous_grabbed_surface.side == \
                    SurfaceSide.RIGHT_WALL and \
                    character.velocity.x > 0.0)):
        character.velocity.x = 0.0
    
    character.velocity = MovementUtils.update_velocity_in_air(
            character.velocity,
            character.actions.delta_scaled,
            character.actions.pressed_jump,
            is_first_jump,
            character.surface_state.horizontal_acceleration_sign,
            character.movement_params)
    
    # Bouncing off ceiling.
    if character.surface_state.is_touching_ceiling and \
            !character.surface_state.is_grabbing_ceiling:
        character.is_rising_from_jump = false
        character.velocity.y = BOUNCE_OFF_CEILING_VELOCITY
    
    return true
