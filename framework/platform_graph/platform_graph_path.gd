# Information for how to move from surface to surface to get from the given origin to the given
# destination.
extends Reference
class_name PlatformGraphPath

# Array<Edge>
var edges: Array

var origin: PositionAlongSurface
var destination: PositionAlongSurface

func _init(edges: Array) -> void:
    self.edges = edges
    self.origin = edges.front().start
    self.destination = edges.back().end
