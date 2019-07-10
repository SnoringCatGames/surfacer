# Information for how to move along a surface from a start position to an end position.
extends PlatformGraphEdge
class_name PlatformGraphIntraSurfaceEdge

var _distance: float

func _init(start: PositionAlongSurface, end: PositionAlongSurface).(start, end) -> void:
    self.start = start
    self.end = end
    self._distance = start.target_point.distance_to(end.target_point)

func _get_weight() -> float:
    return _distance
