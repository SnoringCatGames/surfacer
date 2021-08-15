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
    character.velocity = MovementUtils.cap_velocity(
            character.velocity,
            character.movement_params,
            character.current_max_horizontal_speed)
    return true
