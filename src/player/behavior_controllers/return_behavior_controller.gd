tool
class_name ReturnBehaviorController
extends BehaviorController


# FIXME: -------------------------


const CONTROLLER_NAME := "return"
const IS_ADDED_MANUALLY := false
const INCLUDES_MID_MOVEMENT_PAUSE := false
const INCLUDES_POST_MOVEMENT_PAUSE := false
const COULD_RETURN_TO_START_POSITION := false

# FIXME: --------- Conditionally re-assign this, depending on flags, from things like run-away, follow, collide, wander?
var return_position: PositionAlongSurface


func _init().(
        CONTROLLER_NAME,
        IS_ADDED_MANUALLY,
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    pass


# func _on_active() -> void:
#     ._on_active()


func _on_ready_to_move() -> void:
    ._on_ready_to_move()
    if !is_instance_valid(return_position):
        return_position = player.start_position_along_surface


#func _on_inactive() -> void:
#    ._on_inactive()


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    ._on_navigation_ended(did_navigation_finish)
    if is_active:
        # Don't call _pause_post_movement when returning, since it probably
        # isn't normally desirable, and it would be more complex to configure
        # the pause timing.
        _on_finished()


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


func _move() -> void:
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
