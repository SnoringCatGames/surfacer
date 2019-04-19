# Information for how to move through the air from a start (jump) position on one surface to an
# end (landing) position on another surface.
extends Reference
class_name PlatformGraphEdge

var start_position: PositionAlongSurface
var end_position: PositionAlongSurface

func _init(start_position: PositionAlongSurface, end_position: PositionAlongSurface) -> void:
    self.start_position = start_position
    self.end_position = end_position

# FIXME: Add...
# - instruction set to move from start to end node
# - instruction set to move within start node
# - instruction set to move within end node
