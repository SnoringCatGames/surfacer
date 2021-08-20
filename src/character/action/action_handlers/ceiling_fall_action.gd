class_name CeilingFallAction
extends CharacterActionHandler


const NAME := "CeilingFallAction"
const TYPE := SurfaceType.CEILING
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 330


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if !character.processed_action(CeilingJumpDownAction.NAME) and \
            character.actions.pressed_down:
        character.surface_state.release_ceiling(character)
        # Cancel any velocity toward the ceiling.
        character.velocity.y = \
                character.movement_params.ceiling_fall_velocity_boost
        return true
    else:
        return false
