tool
class_name StaticBehavior
extends Behavior
## This behavior is automatically added no other behavior is configured with
## `is_active_at_start` on the player.


const NAME := "static"
const IS_ADDED_MANUALLY := false
const USES_MOVE_TARGET := false
const INCLUDES_MID_MOVEMENT_PAUSE := false
const INCLUDES_POST_MOVEMENT_PAUSE := false
const COULD_RETURN_TO_START_POSITION := false


func _init().(
        NAME,
        IS_ADDED_MANUALLY,
        USES_MOVE_TARGET,
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    pass


# func _on_active() -> void:
#     ._on_active()


#func _on_ready_to_move() -> void:
#    ._on_ready_to_move()


#func _on_inactive() -> void:
#    ._on_inactive()


#func _on_navigation_ended(did_navigation_finish: bool) -> void:
#    ._on_navigation_ended(did_navigation_finish)


#func _on_physics_process(delta_scaled: float) -> void:
#    ._on_physics_process(delta_scaled)


func _move() -> int:
    # Do nothing.
    return BehaviorMoveResult.VALID_MOVE


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    # NOTE: This replaces the default behavior, rather than extending it.
#    ._on_navigation_ended(did_navigation_finish)
    pass


func get_is_paused() -> bool:
    return true
