class_name AllDefaultAction
extends CharacterActionHandler


const NAME := "AllDefaultAction"
const TYPE := SurfaceType.OTHER
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 10


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    character.just_triggered_jump = false
    
    return true
