class_name UserActionSource
extends PlayerActionSource

const ACTIONS_TO_INPUT_KEYS := {
  "jump": "j",
  "move_up": "mu",
  "move_down": "md",
  "move_left": "ml",
  "move_right": "mr",
  "grab_wall": "gw",
  "face_left": "fl",
  "face_right": "fr",
}

func _init(
        player,
        is_additive: bool) \
        .(
        "HP",
        player,
        is_additive) -> void:
    pass

# Calculates actions for the current frame.
func update(
        actions: PlayerActionState,
        previous_actions: PlayerActionState,
        time_modified_sec: float,
        _modified_delta_sec: float,
        navigation_state: PlayerNavigationState) -> void:
    var is_pressed: bool
    for action in ACTIONS_TO_INPUT_KEYS:
        var input_key: String = ACTIONS_TO_INPUT_KEYS[action]
        is_pressed = Gs.level_input.is_action_pressed(action)
        if !Gs.level_input.is_key_pressed(KEY_CONTROL):
            PlayerActionSource.update_for_key_press(
                    actions,
                    previous_actions,
                    input_key,
                    is_pressed,
                    time_modified_sec,
                    is_additive)

static func get_is_some_user_action_pressed() -> bool:
    for action in ACTIONS_TO_INPUT_KEYS:
        if Gs.level_input.is_action_pressed(action):
            return true
    return false
