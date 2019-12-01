extends PlayerActionSource
class_name InputActionSource

const INPUT_KEYS := [
  "jump",
  "move_up",
  "move_down",
  "move_left",
  "move_right",
]

func _init(player).("HP", player) -> void:
    pass

# Calculates actions for the current frame.
func update(actions: PlayerActionState, previous_actions: PlayerActionState, time_sec: float, \
        delta: float) -> void:
    var is_pressed: bool
    for input_key in INPUT_KEYS:
        is_pressed = Input.is_action_pressed(input_key)
        update_for_key_press(actions, previous_actions, input_key, is_pressed, time_sec)
