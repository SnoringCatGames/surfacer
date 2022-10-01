class_name FloorDashAction
extends CharacterActionHandler


const NAME := "FloorDashAction"
const TYPE := SurfaceType.FLOOR
const IS_JUMP := true
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 260


func _init().(
        NAME,
        TYPE,
        IS_JUMP,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if character.actions.start_dash:
        character.start_dash(character.surface_state.horizontal_facing_sign)
        return true
    else:
        return false
