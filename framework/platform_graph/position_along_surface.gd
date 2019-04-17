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
var player_center: Vector2
# [0,1]
var t: float

func match_current_grab(surface: Surface, player_center: Vector2) -> void:
    self.surface = surface
    self.player_center = player_center
    
    var surface_start
    var surface_range
    var point
    if surface.side == SurfaceSide.FLOOR or surface.side == SurfaceSide.CEILING:
        surface_start = surface.bounding_box.position.x
        surface_range = surface.bounding_box.size.x
        point = player_center.x
    else: # surface.side == SurfaceSide.LEFT_WALL or surface.side == SurfaceSide.RIGHT_WALL
        surface_start = surface.bounding_box.position.y
        surface_range = surface.bounding_box.size.y
        point = player_center.y
    t = (point - surface_start) / surface_range if surface_range > 0 else 0

func match_surface_target_and_collider(surface: Surface, target: Vector2, \
        collider: CollisionShape2D) -> void:
    # FIXME: LEFT OFF HERE: ********
    var shape = collider.shape
    var rotation = collider.transform.get_rotation()
    
    if shape is CircleShape2D:
        # shape.radius
        pass
    elif shape is CapsuleShape2D:
        # shape.radius
        # shape.height
        pass
    elif shape is RectangleShape2D:
        # var width = shape.extents.x * 2
        # var height = shape.extents.y * 2
        pass
    else:
        Utils.error("Invalid CollisionShape2D provided for Player: %s. The supported shapes " + \
                "are: CircleShape2D, CapsuleShape2D, RectangleShape2D." % collider)
    pass
