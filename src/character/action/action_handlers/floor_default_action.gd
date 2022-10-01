class_name FloorDefaultAction
extends CharacterActionHandler


const NAME := "FloorDefaultAction"
const TYPE := SurfaceType.FLOOR
const IS_JUMP := false
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 210


func _init().(
        NAME,
        TYPE,
        IS_JUMP,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    character.jump_count = 0
    character.is_rising_from_jump = false
    
    character.velocity.y = 0.0
    
    return true
