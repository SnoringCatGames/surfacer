extends PlayerAction
class_name CapVelocityAction

const NAME := 'CapVelocityAction'
const TYPE := PlayerActionType.OTHER
const PRIORITY := 10000

func _init().(NAME, TYPE, PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    player.velocity = PlayerMovement.cap_velocity(player.velocity, player.movement_params)
    return true
