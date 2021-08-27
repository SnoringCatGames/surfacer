class_name WallDashAction
extends CharacterActionHandler


const NAME := "WallDashAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 150


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if character.actions.start_dash:
        character.start_dash(-character.surface_state.toward_wall_sign)
        return true
    else:
        return false
