class_name FloorFrictionAction
extends CharacterActionHandler


const NAME := "FloorFrictionAction"
const TYPE := SurfaceType.FLOOR
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 250


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    if !character.processed_action(FloorJumpAction.NAME):
        # Friction.
        var friction_offset: float = \
                Sc.geometry.get_floor_friction_multiplier(character) * \
                character.movement_params.friction_coefficient * \
                character.movement_params.gravity_fast_fall * \
                character.actions.delta_scaled
        friction_offset = clamp(friction_offset, 0, abs(character.velocity.x))
        character.velocity.x += -sign(character.velocity.x) * friction_offset
        
        return true
    else:
        return false
