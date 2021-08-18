tool
class_name ReturnBehavior
extends Behavior


const NAME := "return"
const IS_ADDED_MANUALLY := false
const INCLUDES_MID_MOVEMENT_PAUSE := false
const INCLUDES_POST_MOVEMENT_PAUSE := false
const COULD_RETURN_TO_START_POSITION := false

var return_position: PositionAlongSurface


func _init().(
        NAME,
        IS_ADDED_MANUALLY,
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    pass


# func _on_active() -> void:
#     ._on_active()


func _on_ready_to_move() -> void:
    ._on_ready_to_move()
    
    if character.previous_behavior.returns_to_character_start_position:
        return_position = character.start_position_along_surface
    if character.previous_behavior.returns_to_pre_behavior_position:
        return_position = \
                character.previous_behavior.start_position_along_surface
    assert(is_instance_valid(return_position))


#func _on_inactive() -> void:
#    ._on_inactive()


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    # NOTE: This replaces the default behavior, rather than extending it.
    #._on_navigation_ended(did_navigation_finish)
    if !is_active:
        return
    
    # Don't call _pause_post_movement when returning, since it probably
    # isn't normally desirable, and it would be more complex to configure
    # the pause timing.
    _on_finished()


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


func _move() -> bool:
    return character.navigator.navigate_to_position(return_position, false)
