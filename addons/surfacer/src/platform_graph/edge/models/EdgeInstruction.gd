# An input event to trigger (or untrigger) at a specific time.
class_name EdgeInstruction
extends Reference

var input_key: String
var time: float
# Optional
var is_pressed: bool
# Optional
var position := Vector2.INF

func _init( \
        input_key: String, \
        time: float, \
        is_pressed: bool = false, \
        position := Vector2.INF) -> void:
    # Correct for round-off error.
    if Gs.geometry.are_floats_equal_with_epsilon(time, 0.0, 0.00001):
        time = 0.0
    
    self.input_key = input_key
    self.time = time
    self.is_pressed = is_pressed
    self.position = position

func to_string() -> String:
    return "EdgeInstruction{ %s, %.2f, %s%s }" % [ \
            input_key, \
            time, \
            is_pressed, \
            ", %s" % position if position != Vector2.INF else ""
        ]
