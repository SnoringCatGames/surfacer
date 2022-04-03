class_name PlayerActionSource
extends CharacterActionSource


const ACTIONS_TO_INPUT_KEYS := {
  "jump": "j",
  "move_up": "mu",
  "move_down": "md",
  "move_left": "ml",
  "move_right": "mr",
  "grab": "g",
  "face_left": "fl",
  "face_right": "fr",
}


func _init(
        character,
        is_additive: bool) \
        .(
        "PLAYER",
        character,
        is_additive) -> void:
    pass


# Calculates actions for the current frame.
func update(
        actions: CharacterActionState,
        previous_actions: CharacterActionState,
        time_scaled: float,
        _delta_scaled: float,
        navigation_state: CharacterNavigationState) -> void:
    if !character.is_player_control_active:
        return
    for action in ACTIONS_TO_INPUT_KEYS:
        var input_key: String = ACTIONS_TO_INPUT_KEYS[action]
        var is_pressed: bool = Sc.level_button_input.is_action_pressed(action)
        if !Sc.level_button_input.is_key_pressed(KEY_CONTROL):
            CharacterActionSource.update_for_explicit_key_event(
                    actions,
                    previous_actions,
                    input_key,
                    is_pressed,
                    time_scaled,
                    is_additive)


static func get_is_some_player_action_pressed() -> bool:
    for action in ACTIONS_TO_INPUT_KEYS:
        if Sc.level_button_input.is_action_pressed(action):
            return true
    return false
