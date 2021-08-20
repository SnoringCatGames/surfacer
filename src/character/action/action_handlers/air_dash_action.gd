class_name AirDashAction
extends CharacterActionHandler


const NAME := "AirDashAction"
const TYPE := SurfaceType.AIR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 430


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if character.actions.start_dash:
        character.start_dash(character.surface_state.horizontal_facing_sign)
        return true
    else:
        return false
