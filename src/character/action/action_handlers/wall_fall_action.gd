class_name WallFallAction
extends CharacterActionHandler


const NAME := "WallFallAction"
const TYPE := SurfaceType.WALL
const IS_JUMP := true
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 130


func _init().(
        NAME,
        TYPE,
        IS_JUMP,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if !character.processed_action(WallJumpAction.NAME) and \
            character.surface_state.is_triggering_wall_release:
        character._log(
                "Release wall",
                "",
                CharacterLogType.ACTION,
                false)
        
        # Cancel any velocity toward the wall.
        character.velocity.x = \
                -character.surface_state.toward_wall_sign * \
                character.movement_params.wall_fall_horizontal_boost
        
        return true
    else:
        return false
