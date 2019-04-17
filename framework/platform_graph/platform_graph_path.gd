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
