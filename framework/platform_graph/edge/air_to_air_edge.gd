# Information for how to move through the air from a start position to an end position.
extends Edge
class_name AirToAirEdge

var _start: Vector2
var _end: Vector2

func _init(start: Vector2, end: Vector2) \
        .(_calculate_instructions(start, end)) -> void:
    self._start = start
    self._end = end

func _get_start() -> Vector2:
    return _start

func _get_end() -> Vector2:
    return _end

func _get_start_surface() -> Surface:
    return null

func _get_end_surface() -> Surface:
    return null

# TODO: Implement this

static func _calculate_instructions(start: Vector2, end: Vector2) -> MovementInstructions:
    return null

func _get_class_name() -> String:
    return "AirToAirEdge"

func _get_start_string() -> String:
    return String(_start)

func _get_end_string() -> String:
    return String(_end)
