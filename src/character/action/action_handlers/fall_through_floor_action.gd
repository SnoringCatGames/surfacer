class_name FloorFallThroughAction
extends CharacterActionHandler


const NAME := "FloorFallThroughAction"
const TYPE := SurfaceType.FLOOR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 220


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if character.surface_state.is_falling_through_floors:
        # TODO: If we were already falling through the air, then we should
        #       instead maintain the previous velocity here.
        character.velocity.y = \
                character.movement_params.fall_through_floor_velocity_boost
        return true
    else:
        return false
