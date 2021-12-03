class_name WallClimbAction
extends CharacterActionHandler


const NAME := "WallClimbAction"
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
            !character.processed_action(WallFallAction.NAME):
        if character.actions.pressed_up:
            character.velocity.y = character.current_climb_up_speed
            return true
        elif character.actions.pressed_down:
            character.velocity.y = character.current_climb_down_speed
            return true
    
    return false
