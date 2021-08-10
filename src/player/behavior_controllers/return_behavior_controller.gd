tool
class_name ReturnBehaviorController
extends BehaviorController


# FIXME: -------------------------


const CONTROLLER_NAME := "return"
const IS_ADDED_MANUALLY := false

# FIXME: --------- Conditionally re-assign this, depending on flags, from things like run-away, follow, collide, wander?
var return_position: PositionAlongSurface


func _init().(CONTROLLER_NAME, IS_ADDED_MANUALLY) -> void:
    pass


#func _on_player_ready() -> void:
#    ._on_player_ready()


func _on_attached_to_first_surface() -> void:
    ._on_attached_to_first_surface()
    return_position = player.surface_state.center_position_along_surface


func _on_active() -> void:
    ._on_active()
    player.behavior = PlayerBehaviorType.RETURN


#func _on_ready_to_move() -> void:
#    ._on_ready_to_move()


#func _on_inactive() -> void:
#    ._on_inactive()


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    ._on_navigation_ended(did_navigation_finish)
    
    # FIXME: ---------------------------


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


func move() -> void:
    assert(is_instance_valid(return_position))
    
    var is_navigation_valid := _attempt_navigation()
    
    # FIXME: ---- Move nav success/fail logs into a parent method.
    pass


func _attempt_navigation() -> bool:
    return player.navigator.navigate_to_position(return_position)


#func _update_parameters() -> void:
#    ._update_parameters()
#    if _configuration_warning != "":
#        return
#    _set_configuration_warning("")
