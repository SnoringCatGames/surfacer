class_name CapVelocityAction
extends PlayerActionHandler

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

func process(player: Player) -> bool:
    player.velocity = MovementUtils.cap_velocity(
            player.velocity,
            player.movement_params,
            player.current_max_horizontal_speed)
    return true
