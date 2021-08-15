class_name WallJumpAction
extends CharacterActionHandler


const NAME := "WallJumpAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 120


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if character.actions.just_pressed_jump:
        character.surface_state.release_wall(character)
        character.jump_count = 1
        character.just_triggered_jump = true
        character.is_rising_from_jump = true
        
        character.velocity.y = character.movement_params.jump_boost
        
        # Give a little boost to get the character away from the wall, so they can
        # still be pushing themselves into the wall when they start the jump.
        character.velocity.x = \
                -character.surface_state.toward_wall_sign * \
                character.movement_params.wall_jump_horizontal_boost
        
        return true
    else:
        return false
