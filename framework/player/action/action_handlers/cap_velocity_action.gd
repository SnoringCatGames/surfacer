extends PlayerActionHandler
class_name CapVelocityAction

const NAME := 'CapVelocityAction'
const TYPE := PlayerActionSurfaceType.OTHER
const PRIORITY := 10010

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    player.velocity = MovementUtils.cap_velocity(player.velocity, player.movement_params)
    return true
