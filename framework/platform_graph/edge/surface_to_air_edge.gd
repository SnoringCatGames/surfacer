# Information for how to move from a surface to a position in the air.
extends Edge
class_name SurfaceToAirEdge

var start_position_along_surface: PositionAlongSurface
var _end: Vector2

func _init(start: PositionAlongSurface, end: Vector2) \
        .(_calculate_instructions(start, end)) -> void:
    self.start_position_along_surface = start
    self._end = end

func _get_start() -> Vector2:
    return start_position_along_surface.target_point

func _get_end() -> Vector2:
    return _end

# TODO: Implement this

static func _calculate_instructions( \
        start: PositionAlongSurface, end: Vector2) -> MovementInstructions:
    return null

func _get_class_name() -> String:
    return "SurfaceToAirEdge"

func _get_start_string() -> String:
    return start_position_along_surface.to_string()

func _get_end_string() -> String:
    return String(_end)
