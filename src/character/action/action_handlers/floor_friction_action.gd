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
        var friction_multiplier: float = \
                character.surface_state.grabbed_surface.properties \
                    .friction_multiplier if \
                character.surface_state.is_grabbing_surface else \
                1.0
        var friction_offset: float = \
                friction_multiplier * \
                character.movement_params.friction_coefficient * \
                character.movement_params.gravity_fast_fall * \
                character.actions.delta_scaled
        friction_offset = clamp(friction_offset, 0, abs(character.velocity.x))
        character.velocity.x += -sign(character.velocity.x) * friction_offset
        
        return true
    else:
        return false
