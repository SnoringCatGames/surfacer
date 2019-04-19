# Represents a position along a surface.
# 
# - Rather than considering polyline length, this only specifies the position along the axis the
#   surface is aligned to.
# - min x/y -> t = 0; max x/y -> t = 1. This ignores the ordering of the surface vertices.
# 
# The position always indicates the center of the player's bounding box.
extends Reference
class_name PositionAlongSurface

var surface: Surface
var target_point: Vector2
# How far the target point is along the axially-aligned range between the surface's end points.
# [0,1]
var t: float

func reset() -> void:
    self.surface = null
    self.target_point = Vector2.INF
    self.t = 0.0

func match_current_grab(surface: Surface, player_center: Vector2) -> void:
    self.surface = surface
    self.target_point = player_center
    self.t = _calculate_t(surface, player_center)

func match_surface_target_and_collider(surface: Surface, target_point: Vector2, \
        collider: CollisionShape2D = null) -> void:
    self.surface = surface
    self.target_point = \
            _calculate_target_point_for_center_of_collider(surface, target_point, collider)
    self.t = _calculate_t(surface, target_point)
    
static func _calculate_target_point_for_center_of_collider(surface: Surface, \
        target_point: Vector2, collider: CollisionShape2D = null) -> Vector2:
    var point_on_surface = _project_point_on_surface(surface, target_point)
    
    if collider == null:
        return point_on_surface
    
    var is_surface_horizontal = SurfaceSide.FLOOR or surface.side == SurfaceSide.CEILING
    var shape = collider.shape
    var rotation = collider.transform.get_rotation()
    var is_rotated_90_degrees = abs(fmod(rotation + PI * 2, PI) - PI / 2) < Geometry.FLOAT_EPSILON
    
    # Ensure that collision boundaries are only ever axially aligned.
    assert(is_rotated_90_degrees or abs(rotation) < Geometry.FLOAT_EPSILON)
    
    var distance_to_center: float
    if shape is CircleShape2D:
        distance_to_center = shape.radius
    elif shape is CapsuleShape2D:
        distance_to_center = shape.radius
        if is_surface_horizontal != is_rotated_90_degrees:
            distance_to_center += shape.height
    elif shape is RectangleShape2D:
        distance_to_center = shape.extents.y if is_surface_horizontal else shape.extents.x
    else:
        Utils.error("Invalid CollisionShape2D provided for Player: %s. The supported shapes " + \
                "are: CircleShape2D, CapsuleShape2D, RectangleShape2D." % collider)
    
    return point_on_surface + distance_to_center * surface.normal

# Calculates how far the given target point is along the axially-aligned range between the given
# surface's end points. Measured as a ratio between 0 and 1.
static func _calculate_t(surface: Surface, target_point: Vector2) -> float:
    var surface_start
    var surface_range
    var point
    if surface.side == SurfaceSide.FLOOR or surface.side == SurfaceSide.CEILING:
        surface_start = surface.bounding_box.position.x
        surface_range = surface.bounding_box.size.x
        point = target_point.x
    else: # surface.side == SurfaceSide.LEFT_WALL or surface.side == SurfaceSide.RIGHT_WALL
        surface_start = surface.bounding_box.position.y
        surface_range = surface.bounding_box.size.y
        point = target_point.y
    return (point - surface_start) / surface_range if surface_range > 0 else 0.0

# Calculates where the alially-aligned surface-side-normal that goes through the given point would
# intersect with the surface.
static func _project_point_on_surface(surface: Surface, target: Vector2) -> Vector2:
    # Check whether the target lies outside the surface boundaries.
    var start_vertex = surface.vertices[0]
    var end_vertex = surface.vertices[surface.vertices.size() - 1]
    if surface.side == SurfaceSide.FLOOR and target.x <= start_vertex:
        return start_vertex
    elif surface.side == SurfaceSide.FLOOR and target.x >= end_vertex:
        return end_vertex
    if surface.side == SurfaceSide.CEILING and target.x >= start_vertex:
        return start_vertex
    elif surface.side == SurfaceSide.CEILING and target.x <= end_vertex:
        return end_vertex
    if surface.side == SurfaceSide.RIGHT_WALL and target.y <= start_vertex:
        return start_vertex
    elif surface.side == SurfaceSide.RIGHT_WALL and target.y >= end_vertex:
        return end_vertex
    if surface.side == SurfaceSide.LEFT_WALL and target.y >= start_vertex:
        return start_vertex
    elif surface.side == SurfaceSide.LEFT_WALL and target.y <= end_vertex:
        return end_vertex
    else:
        # Target lies within the surface boundaries.
        
        # Calculate a segment that represents the alially-aligned surface-side-normal.
        var segment_a: Vector2
        var segment_b: Vector2
        if surface.side == SurfaceSide.FLOOR or surface.side == SurfaceSide.CEILING:
            segment_a = Vector2(target.x, surface.bounding_box.position.y)
            segment_b = Vector2(target.x, surface.bounding_box.end.y)
        else: # surface.side == SurfaceSide.LEFT_WALL or surface.side == SurfaceSide.RIGHT_WALL
            segment_a = Vector2(surface.bounding_box.position.x, target.y)
            segment_b = Vector2(surface.bounding_box.end.x, target.y)
        
        var intersection: Vector2 = Geometry.get_intersection_of_segment_and_polyline(segment_a, \
                segment_b, surface.vertices)
        assert(intersection != Vector2.INF)
        return intersection
