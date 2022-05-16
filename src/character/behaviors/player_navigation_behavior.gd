tool
class_name PlayerNavigationBehavior
extends Behavior


const NAME := "player_navigation"
const IS_ADDED_MANUALLY := false
const USES_MOVE_TARGET := false
const INCLUDES_MID_MOVEMENT_PAUSE := false
const INCLUDES_POST_MOVEMENT_PAUSE := false
const COULD_RETURN_TO_START_POSITION := false

var new_selection: PointerSelectionPosition
var last_selection: PointerSelectionPosition
var pre_selection: PointerSelectionPosition

var _was_last_input_a_touch := false


func _init().(
        NAME,
        IS_ADDED_MANUALLY,
        USES_MOVE_TARGET,
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    pass


func _ready() -> void:
    self.new_selection = PointerSelectionPosition.new(character)
    self.last_selection = PointerSelectionPosition.new(character)
    self.pre_selection = PointerSelectionPosition.new(character)


#func _on_active() -> void:
#    ._on_active()


#func _on_ready_to_move() -> void:
#    ._on_ready_to_move()


#func _on_inactive() -> void:
#    ._on_inactive()


#func _on_navigation_ended(did_navigation_finish: bool) -> void:
#    ._on_navigation_ended(did_navigation_finish)


func _on_physics_process(delta_scaled: float) -> void:
    ._on_physics_process(delta_scaled)
    _handle_pointer_selections()


func _unhandled_input(event: InputEvent) -> void:
    if _is_ready and \
            !character._is_destroyed and \
            Sc.gui.is_player_interaction_enabled and \
            character.navigation_state.is_currently_navigating and \
            Su.movement.do_player_actions_interrupt_navigation and \
            event is InputEventKey and \
            Sc.project_settings.movement_action_key_set.has(event.scancode):
        _was_last_input_a_touch = false
        character.navigator.stop(true)
        trigger(false)


func _handle_pointer_selections() -> void:
    if !new_selection.get_has_selection():
        return
    
    character._log(
            "Pointer sel",
            "target=%s; %s" % [
                Sc.utils.get_vector_string(new_selection.pointer_position, 1),
                new_selection.navigation_destination.to_string(false) if \
                new_selection.get_is_selection_navigable() else \
                "NO MATCH",
            ],
            CharacterLogType.ACTION,
            false)
    
    if new_selection.get_is_selection_navigable():
        _was_last_input_a_touch = true
        last_selection.copy(new_selection)
        trigger(false)
    else:
        Sc.audio.play_sound("nav_select_fail")
        if Su.cancel_active_player_control_on_invalid_nav_selection:
            character.set_is_player_control_active(false)
    
    new_selection.clear()
    pre_selection.clear()


func _move() -> int:
    if !_was_last_input_a_touch:
        return BehaviorMoveResult.VALID_MOVE
    
    assert(last_selection.get_is_selection_navigable())
    var is_navigation_valid: bool = \
            character.navigator.navigate_path(last_selection.path, false, true)
    Sc.audio.play_sound("nav_select_success")
    
    return BehaviorMoveResult.VALID_MOVE if \
            is_navigation_valid else \
            BehaviorMoveResult.INVALID_MOVE


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    # NOTE: This replaces the default behavior, rather than extending it.
#    ._on_navigation_ended(did_navigation_finish)
    
    if !is_active:
        return
    
    # Don't call _pause_post_movement when returning, since it probably
    # isn't normally desirable, and it would be more complex to configure
    # the pause timing.
    _on_finished()


#func _on_finished() -> void:
#    ._on_finished()
