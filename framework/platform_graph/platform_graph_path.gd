# Information for how to move from surface to surface to get from the given origin to the given
# destination.
# 
# We do not use separate data structures to represent movement along a surface from an earlier
# landing position to a later jump position. Instead, the navigator automatically handles this by
# simply moving up/down/left/right along the surface in the direction of the next jump position.
# 
# There are one fewer edges than surface nodes. The navigator has special logic for moving within
# the last surface node from the landing position of the last edge to the destination position
# within the surface.
extends Reference
class_name PlatformGraphPath

var origin: PositionAlongSurface
var destination: PositionAlongSurface
# Each PlatformGraphEdge contains a reference to its source and destination Surface nodes, so 
# we don't need to store them separately.
# Array<PlatformGraphEdge>
var edges: Array

func _init(origin: PositionAlongSurface, destination: PositionAlongSurface, edges: Array) -> void:
    self.origin = origin
    self.destination = destination
    self.edges = edges
