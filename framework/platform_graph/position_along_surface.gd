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

# An approximation for the center of the player's collision boundary corresponding to this position
# on the surface.
var target_point: Vector2

# How far the target point is along the axially-aligned range between the surface's end points.
# [0,1]
var t: float

# Used for debugging. May not always be set.
var target_projection_onto_surface: Vector2

func reset() -> void:
    self.surface = null
    self.target_point = Vector2.INF
    self.t = 0.0

func match_current_grab(surface: Surface, player_center: Vector2) -> void:
    self.surface = surface
    self.target_point = player_center
    self.t = _calculate_t(surface, player_center)

func match_surface_target_and_collider(surface: Surface, target_point: Vector2, \
        collider_half_width_height: Vector2) -> void:
    self.surface = surface
    self.target_point = _calculate_target_point_for_center_of_collider(surface, target_point, \
            collider_half_width_height)
    self.t = _calculate_t(surface, target_point)
    
func _calculate_target_point_for_center_of_collider(surface: Surface, \
        target_point: Vector2, collider_half_width_height: Vector2) -> Vector2:
    var point_on_surface: Vector2 = Geometry.project_point_onto_surface(target_point, surface)
    self.target_projection_onto_surface = point_on_surface
    
    var is_surface_horizontal = \
            surface.side == SurfaceSide.FLOOR or surface.side == SurfaceSide.CEILING    
    var distance_to_center := \
            collider_half_width_height.y if is_surface_horizontal else collider_half_width_height.x
    
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