# Information for how to move through the air from a start (jump) position on one surface to an
# end (landing) position on another surface.
# 
# We do not use separate data structures to represent movement along a surface from an earlier
# landing position to a later jump position. Instead, the navigator automatically handles this by
# simply moving up/down/left/right along the surface in the direction of the next jump position.
# 
# A special "edge" case is used to handle the destination (rest) position on the final surface.
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
