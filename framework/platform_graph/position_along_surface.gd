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
# [0,1]
var t: float

func update(surface: Surface, position_world_coord: Vector2) -> void:
    self.surface = surface
    
    var surface_start
    var surface_range
    var point
    if surface.side == SurfaceSide.FLOOR or surface.side == SurfaceSide.CEILING:
        surface_start = surface.bounding_box.position.x
        surface_range = surface.bounding_box.size.x
        point = position_world_coord.x
    else: # surface.side == SurfaceSide.LEFT_WALL or surface.side == SurfaceSide.RIGHT_WALL
        surface_start = surface.bounding_box.position.y
        surface_range = surface.bounding_box.size.y
        point = position_world_coord.y
    t = (point - surface_start) / surface_range if surface_range > 0 else 0
