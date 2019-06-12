# An input event to trigger (or untrigger) at a specific time.
extends Reference
class_name PlayerInstruction

var input_key: String
var time: float
# Optional
var is_pressed: bool
# Optional
var position: Vector2

func _init(input_key: String, time: float, is_pressed: bool = false, \
        position := Vector2.INF) -> void:
    self.input_key = input_key
    self.time = time
    self.is_pressed = is_pressed
    self.position = position
