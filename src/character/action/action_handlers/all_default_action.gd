class_name AllDefaultAction
extends CharacterActionHandler


const NAME := "AllDefaultAction"
const TYPE := SurfaceType.OTHER
const IS_JUMP := false
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 10


func _init().(
        NAME,
        TYPE,
        IS_JUMP,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    character.just_triggered_jump = false
    
    return true
