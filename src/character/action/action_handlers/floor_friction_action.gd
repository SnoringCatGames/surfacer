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
        
        # FIXME: LEFT OFF HERE: REMOVE THIS OLD LOGIC ----------------
#        var friction_multiplier: float = \
#                character.surface_state.grabbed_surface.properties \
#                    .friction_multiplier if \
#                character.surface_state.is_grabbing_surface else \
#                1.0
#        var friction_offset: float = \
#                friction_multiplier * \
#                character.movement_params.friction_coefficient * \
#                character.movement_params.gravity_fast_fall * \
#                character.actions.delta_scaled
#        friction_offset = clamp(friction_offset, 0, abs(character.velocity.x))
#        character.velocity.x += -sign(character.velocity.x) * friction_offset
        
        var acceleration_sign: int = \
                character.surface_state.horizontal_acceleration_sign
        var speed_sign := sign(character.velocity.x)
        var is_character_pressing_move := acceleration_sign != 0.0
        var friction_multiplier: float = \
                character.surface_state.grabbed_surface.properties \
                    .friction_multiplier if \
                character.surface_state.is_grabbing_surface else \
                1.0
        
        if is_character_pressing_move:
            # -   Apply a friction offset that counters the character's
            #     acceleration.
            # -   This friction offset will be _inversely_ proportional to the
            #     coefficient of friction.
            # -   This is what makes slippery ice difficult to build speed on.
            # -   Force a minimum speed value, in order to prevent early
            #     acceleration from being cancelled-out by the min-speed cutoff.
            var default_move_offset: float = \
                    character.movement_params.walk_acceleration * \
                    character.actions.delta_scaled
            var friction_factor: float = \
                    character.movement_params \
                        .friction_coefficient_accelerating * \
                    friction_multiplier
            var friction_offset: float = \
                    default_move_offset / \
                    (friction_factor + 1.0)
            friction_offset = clamp(friction_offset, 0.0, default_move_offset)
            friction_offset *= -acceleration_sign
            character.velocity.x += friction_offset
            
            if abs(character.velocity.x) < Su.movement.min_horizontal_speed:
                character.velocity.x = \
                        (Su.movement.min_horizontal_speed + 0.1) * \
                        acceleration_sign
            
        else:
            # -   Apply a friction offset that counters the character's speed.
            # -   This friction offset will be proportional to the coefficient
            #     of friction.
            var friction_factor: float = \
                    character.movement_params \
                        .friction_coefficient_constant_speed * \
                    friction_multiplier
            var friction_magnitude: float = \
                    character.movement_params.gravity_fast_fall * \
                    character.actions.delta_scaled * \
                    friction_factor
            friction_magnitude = clamp(
                    friction_magnitude,
                    0.0,
                    abs(character.velocity.x))
            var friction_offset := friction_magnitude * -speed_sign
            character.velocity.x += friction_offset
        
        return true
    else:
        return false
