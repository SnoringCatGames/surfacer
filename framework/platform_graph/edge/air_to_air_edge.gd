# Information for how to move through the air from a start position to an end position.
extends Edge
class_name AirToAirEdge

var start: Vector2
var end: Vector2

func _init(start: Vector2, end: Vector2) \
        .(_calculate_instructions(start, end)) -> void:
    self.start = start
    self.end = end

# TODO: Implement this

static func _calculate_instructions(start: Vector2, end: Vector2) -> MovementInstructions:
    return null

func _get_class_name() -> String:
    return "AirToAirEdge"

func _get_start_string() -> String:
    return String(start)

func _get_end_string() -> String:
    return String(end)
