tool
class_name ReturnBehaviorController
extends BehaviorController


# FIXME: -------------------------


const CONTROLLER_NAME := "return"
const IS_ADDED_MANUALLY := false


func _init().(CONTROLLER_NAME, IS_ADDED_MANUALLY) -> void:
    pass


#func _on_player_ready() -> void:
#    pass


#func _on_attached_to_first_surface() -> void:
#    pass


func _on_active() -> void:
    player.behavior = PlayerBehaviorType.RETURN


#func _on_ready_to_move() -> void:
#    pass


#func _on_inactive() -> void:
#    pass


#func _on_physics_process(delta: float) -> void:
#    pass
