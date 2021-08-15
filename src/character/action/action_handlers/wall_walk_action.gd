class_name WallWalkAction
extends CharacterActionHandler


const NAME := "WallWalkAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 140


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if !character.processed_action(WallJumpAction.NAME) and \
            !character.processed_action(WallFallAction.NAME) and \
            character.surface_state.is_touching_wall and \
            character.surface_state.is_touching_floor and \
            character.actions.pressed_down:
        character.surface_state.release_wall(character)
        return true
    else:
        return false
