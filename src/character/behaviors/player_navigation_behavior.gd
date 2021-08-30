tool
class_name PlayerNavigationBehavior
extends Behavior


const NAME := "player_navigation"
const IS_ADDED_MANUALLY := false
const INCLUDES_MID_MOVEMENT_PAUSE := false
const INCLUDES_POST_MOVEMENT_PAUSE := false
const COULD_RETURN_TO_START_POSITION := false

var cancels_navigation_on_key_press := true

var new_selection: PointerSelectionPosition
var last_selection: PointerSelectionPosition
var pre_selection: PointerSelectionPosition

var _was_last_input_a_touch := false


func _init().(
        NAME,
        IS_ADDED_MANUALLY,
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


func _on_physics_process(delta: float) -> void:
    ._on_physics_process(delta)
    _handle_pointer_selections()


func _unhandled_input(event: InputEvent) -> void:
    if _is_ready and \
            !character._is_destroyed and \
            Sc.gui.is_player_interaction_enabled and \
            character.navigation_state.is_currently_navigating and \
            cancels_navigation_on_key_press and \
            event is InputEventKey:
        _was_last_input_a_touch = false
        character.navigator.stop()
        trigger(false)


func _handle_pointer_selections() -> void:
    if !new_selection.get_has_selection():
        return
    
    character._log(
            "New pointer selection:%8s;%8.3fs;P%29s; %s" % [
                character.character_name,
                Sc.time.get_play_time(),
                str(new_selection.pointer_position),
                new_selection.navigation_destination.to_string() if \
                new_selection.get_is_selection_navigable() else \
                "[No matching surface]",
            ],
            CharacterLogType.ACTION,
            false)
    
    if new_selection.get_is_selection_navigable():
        _was_last_input_a_touch = true
        last_selection.copy(new_selection)
        trigger(false)
    else:
        character._log(
                "Target is too far from any surface",
                CharacterLogType.ACTION,
                false)
        Sc.audio.play_sound("nav_select_fail")
    
    new_selection.clear()
    pre_selection.clear()


func _move() -> bool:
    if !_was_last_input_a_touch:
        return true
    
    assert(last_selection.get_is_selection_navigable())
    var is_navigation_valid: bool = \
            character.navigator.navigate_path(last_selection.path)
    Sc.audio.play_sound("nav_select_success")
    
    return is_navigation_valid
