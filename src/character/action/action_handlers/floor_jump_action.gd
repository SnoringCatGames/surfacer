class_name FloorJumpAction
extends CharacterActionHandler


const NAME := "FloorJumpAction"
const TYPE := SurfaceType.FLOOR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 230


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if !character.processed_action(FloorFallThroughAction.NAME) and \
            character.actions.just_pressed_jump:
        character.jump_count = 1
        character.just_triggered_jump = true
        character.is_rising_from_jump = true
        character.velocity.y = character.movement_params.jump_boost

        return true
    else:
        return false
