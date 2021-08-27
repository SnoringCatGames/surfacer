class_name WallFallAction
extends CharacterActionHandler


const NAME := "WallFallAction"
const TYPE := SurfaceType.WALL
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 130


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if !character.processed_action(WallJumpAction.NAME) and \
            character.surface_state.is_triggering_wall_release:
        character._log(
                "Releasing wall:       %8s;%8.3fs;P%29s" % [
                    character.character_name,
                    Sc.time.get_play_time(),
                    str(character.position),
                ],
                CharacterLogType.ACTION,
                true)
        
        character.surface_state.release_wall()
        # Cancel any velocity toward the wall.
        character.velocity.x = \
                -character.surface_state.toward_wall_sign * \
                character.movement_params.wall_fall_horizontal_boost
        return true
    else:
        return false
