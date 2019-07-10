# Information for how to move from a start position to an end position.
extends Reference
class_name PlatformGraphEdge

var start: PositionAlongSurface
var end: PositionAlongSurface

var weight: float setget ,_get_weight

func _init(start: PositionAlongSurface, end: PositionAlongSurface) -> void:
    self.start = start
    self.end = end

func _get_weight() -> float:
    Utils.error("Abstract PlatformGraphEdge._get_weight is not implemented")
    return INF
