# Information for how to move from surface to surface to get from the given origin to the given
# destination.
extends Reference
class_name PlatformGraphPath

# Array<Edge>
var edges: Array

# PositionAlongSurface|Vector2
var origin
# PositionAlongSurface|Vector2
var destination

func _init(edges: Array) -> void:
    self.edges = edges
    self.origin = edges.front().start
    self.destination = edges.back().end

func push_front(edge: Edge) -> void:
    if edge.end is PositionAlongSurface:
        assert(Geometry.are_points_equal_with_epsilon(edge.end.target_point, origin.target_point))
    else:
        assert(Geometry.are_points_equal_with_epsilon(edge.end, origin.target_point))
    
    self.edges.push_front(edge)
    self.origin = edge.start

func push_back(edge: Edge) -> void:
    if edge.start is PositionAlongSurface:
        assert(Geometry.are_points_equal_with_epsilon(edge.start.target_point, destination.target_point))
    else:
        assert(Geometry.are_points_equal_with_epsilon(edge.start, destination.target_point))
    
    self.edges.push_back(edge)
    self.destination = edge.end
