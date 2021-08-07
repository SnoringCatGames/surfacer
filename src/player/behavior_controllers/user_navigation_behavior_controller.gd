tool
class_name UserNavigationBehaviorController
extends BehaviorController


const CONTROLLER_NAME := "user_navigation"
const IS_ADDED_MANUALLY := false

var cancels_navigation_on_key_press := true

var new_selection: PointerSelectionPosition
var last_selection: PointerSelectionPosition
var pre_selection: PointerSelectionPosition


func _init().(CONTROLLER_NAME, IS_ADDED_MANUALLY) -> void:
    pass


func _ready() -> void:
    self.new_selection = PointerSelectionPosition.new(player)
    self.last_selection = PointerSelectionPosition.new(player)
    self.pre_selection = PointerSelectionPosition.new(player)


#func _on_player_ready() -> void:
#    pass


#func _on_active() -> void:
#    pass


#func _on_inactive() -> void:
#    pass


func _on_physics_process(delta: float) -> void:
    _handle_pointer_selections()


func _unhandled_input(event: InputEvent) -> void:
    if _is_ready and \
            !player._is_destroyed and \
            Sc.gui.is_user_interaction_enabled and \
            player.navigator.is_currently_navigating and \
            cancels_navigation_on_key_press and \
            event is InputEventKey:
        player.navigator.stop()
        _set_is_active(false)


func _handle_pointer_selections() -> void:
    if new_selection.get_has_selection():
        player._log_player_event(
                "NEW POINTER SELECTION:%8s;%8.3fs;P%29s; %s", [
                    player.player_name,
                    Sc.time.get_play_time(),
                    str(new_selection.pointer_position),
                    new_selection.navigation_destination.to_string() if \
                    new_selection.get_is_selection_navigatable() else \
                    "[No matching surface]"
                ],
                true)
        
        if new_selection.get_is_selection_navigatable():
            last_selection.copy(new_selection)
            player.behavior = PlayerBehaviorType.USER_NAVIGATE
            _set_is_active(true)
            player.navigator.navigate_path(last_selection.path)
            Sc.audio.play_sound("nav_select_success")
        else:
            player._log_player_event(
                    "TARGET IS TOO FAR FROM ANY SURFACE", [], true)
            Sc.audio.play_sound("nav_select_fail")
        
        new_selection.clear()
        pre_selection.clear()
