class_name CapVelocityAction
extends CharacterActionHandler


const NAME := "CapVelocityAction"
const TYPE := SurfaceType.OTHER
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 10020


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    var max_horizontal_speed: float
    if character.current_max_horizontal_speed == \
            character.movement_params.max_horizontal_speed_default and \
            character.surface_state.is_grabbing_surface:
        max_horizontal_speed = \
                character.movement_params.max_horizontal_speed_default * \
                character.movement_params.intra_surface_edge_speed_multiplier
    else:
        max_horizontal_speed = character.current_max_horizontal_speed
    
    character.velocity = MovementUtils.cap_velocity(
            character.velocity,
            character.movement_params,
            max_horizontal_speed)
    
    return true
