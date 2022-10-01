class_name WallDefaultAction
extends CharacterActionHandler


const NAME := "WallDefaultAction"
const TYPE := SurfaceType.WALL
const IS_JUMP := false
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 110


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
    character.velocity.x = 0.0
    character.velocity.y = 0.0
    
    return true
