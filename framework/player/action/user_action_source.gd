extends PlayerActionSource
class_name UserActionSource

const INPUT_KEYS := [
  "jump",
  "move_up",
  "move_down",
  "move_left",
  "move_right",
]

func _init(player, is_additive: bool).("HP", player, is_additive) -> void:
    pass

# Calculates actions for the current frame.
func update(actions: PlayerActionState, previous_actions: PlayerActionState, time_sec: float, \
        delta: float, navigation_state: PlayerNavigationState) -> void:
    var is_pressed: bool
    for input_key in INPUT_KEYS:
        is_pressed = Input.is_action_pressed(input_key)
        update_for_key_press(actions, previous_actions, input_key, is_pressed, time_sec)

static func get_is_some_user_action_pressed() -> bool:
    for input_key in INPUT_KEYS:
        if Input.is_action_pressed(input_key):
            return true
    return false
