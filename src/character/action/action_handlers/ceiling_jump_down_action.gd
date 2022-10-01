class_name CeilingJumpDownAction
extends CharacterActionHandler


const NAME := "CeilingJumpDownAction"
const TYPE := SurfaceType.CEILING
const IS_JUMP := true
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 320


func _init().(
        NAME,
        TYPE,
        IS_JUMP,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if character.actions.just_pressed_jump:
        character.jump_count = 1
        character.just_triggered_jump = true
        character.is_rising_from_jump = false
        
        character.velocity.y = -character.movement_params.jump_boost
        
        return true
    else:
        return false
