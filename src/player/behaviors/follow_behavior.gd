tool
class_name FollowBehavior, \
"res://addons/surfacer/assets/images/editor_icons/follow_behavior.png"
extends Behavior


# FIXME: -------------------------


const NAME := "follow"
const IS_ADDED_MANUALLY := true
const INCLUDES_MID_MOVEMENT_PAUSE := true
const INCLUDES_POST_MOVEMENT_PAUSE := true
const COULD_RETURN_TO_START_POSITION := true

# FIXME: ---------------- Set this
var follow_target: ScaffolderPlayer


func _init().(
        NAME,
        IS_ADDED_MANUALLY,
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    pass


#func _on_active() -> void:
#    ._on_active()


func _on_ready_to_move() -> void:
    ._on_ready_to_move()
    assert(is_instance_valid(follow_target))
    _move()


#func _on_inactive() -> void:
#    ._on_inactive()


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    # NOTE: This replaces the default behavior, rather than extending it.
    #._on_navigation_ended(did_navigation_finish)
    if !is_active:
        return
    
    # FIXME: LEFT OFF HERE: --------------
    # - _pause_mid_movement()
    # - _pause_post_movement()
    # - Continue following, or stop, depending on whether we're too far.
    # - How to stop/pause when we're too close?
    _pause_mid_movement()


func _on_physics_process(delta: float) -> void:
    ._on_physics_process(delta)
    


# FIXME: ------- Call this
func on_detached() -> void:
    # FIXME: ---------------------------------------------
    _pause_post_movement()
    
    if player.navigation_state.is_currently_navigating and \
            is_active:
        player.navigator.stop()


func _move() -> bool:
    # FIXME: -------------------
    return false


#func _update_parameters() -> void:
#    ._update_parameters()
#
#    if _configuration_warning != "":
#        return
#
#    # FIXME: ----------------------------
#
#    _set_configuration_warning("")
