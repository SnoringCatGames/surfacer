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
        input_key := "", \
        time := INF, \
        is_pressed := false, \
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

func load_from_json_object( \
        json_object: Dictionary, \
        context: Dictionary) -> void:
    input_key = json_object.k
    time = json_object.t
    is_pressed = json_object.i
    if json_object.has("p"):
        position = Gs.utils.from_json_object(json_object.p)

func to_json_object() -> Dictionary:
    var json_object := {
        k = input_key,
        t = time,
        i = is_pressed,
    }
    if position != Vector2.INF:
        json_object.p = Gs.utils.to_json_object(position)
    return json_object
