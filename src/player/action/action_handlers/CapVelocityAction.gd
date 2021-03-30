class_name CapVelocityAction
extends PlayerActionHandler

const NAME := "CapVelocityAction"
const TYPE := SurfaceType.OTHER
const PRIORITY := 10020

func _init().( \
        NAME, \
        TYPE, \
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    player.velocity = MovementUtils.cap_velocity( \
            player.velocity, \
            player.movement_params, \
            player.current_max_horizontal_speed)
    return true
