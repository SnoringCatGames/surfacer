class_name AirJumpAction
extends CharacterActionHandler


const NAME := "AirJumpAction"
const TYPE := SurfaceType.AIR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 320


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if character.actions.just_pressed_jump and \
            character.jump_count < character.movement_params.max_jump_chain:
        character.jump_count += 1
        character.just_triggered_jump = true
        character.is_rising_from_jump = true
        character.velocity.y = character.movement_params.jump_boost

        return true
    else:
        return false
