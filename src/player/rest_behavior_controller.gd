tool
class_name RestBehaviorController
extends BehaviorController


const CONTROLLER_NAME := "RestBehaviorController"


func _init().(CONTROLLER_NAME) -> void:
    pass


func _enter_tree() -> void:
    if Engine.editor_hint:
        Sc.logger.error(
                "RestBehaviorController should not be added to your scene " +
                "manually.")


#func _on_player_ready() -> void:
#    pass


func _on_active() -> void:
    player.behavior = PlayerBehaviorType.REST


#func _on_inactive() -> void:
#    pass


#func _on_physics_process(delta: float) -> void:
#    pass
