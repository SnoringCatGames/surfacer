class_name CapVelocityAction
extends CharacterActionHandler


const NAME := "CapVelocityAction"
const TYPE := SurfaceType.OTHER
const IS_JUMP := false
const USES_RUNTIME_PHYSICS := true
const PRIORITY := 10020


func _init().(
        NAME,
        TYPE,
        IS_JUMP,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    var max_horizontal_speed: float = \
            character.get_current_surface_max_horizontal_speed() if \
            character.surface_state.is_grabbing_surface else \
            character.get_current_air_max_horizontal_speed()
    
    character.velocity = MovementUtils.cap_velocity(
            character.velocity,
            character.movement_params,
            max_horizontal_speed)
    
    return true
