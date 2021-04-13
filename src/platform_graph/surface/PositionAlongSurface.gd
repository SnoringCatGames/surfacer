# Represents a position along a surface.
# 
# -   Rather than considering polyline length, this only specifies the position
#     along the axis the surface is aligned to.
# -   min x/y -> t = 0; max x/y -> t = 1. This ignores the ordering of the
#     surface vertices.
# 
# The position always indicates the center of the player's bounding box.
class_name PositionAlongSurface
extends Reference

var surface: Surface

# An approximation for the center of the player's collision boundary
# corresponding to this position on the surface.
var target_point := Vector2.INF

# Used for debugging. May not always be set.
var target_projection_onto_surface := Vector2.INF

var side: int setget ,_get_side

func _init(position_to_copy = null) -> void:
    if position_to_copy != null:
        copy(self, position_to_copy)

func reset() -> void:
    self.surface = null
    self.target_point = Vector2.INF
    self.target_projection_onto_surface = Vector2.INF

func match_current_grab( \
        surface: Surface, \
        player_center: Vector2) -> void:
    self.surface = surface
    self.target_point = player_center
    self.target_projection_onto_surface = Vector2.INF

func match_surface_target_and_collider( \
        surface: Surface, \
        target_point: Vector2, \
        collider_half_width_height: Vector2, \
        offsets_target_by_half_width_height := false, \
        clips_to_surface_bounds := false) -> void:
    self.surface = surface
    self.target_point = \
            _clip_and_project_target_point_for_center_of_collider( \
                    surface, \
                    target_point, \
                    collider_half_width_height, \
                    offsets_target_by_half_width_height, \
                    clips_to_surface_bounds)
    
func _clip_and_project_target_point_for_center_of_collider( \
        surface: Surface, \
        target_point: Vector2, \
        collider_half_width_height: Vector2, \
        offsets_target_by_half_width_height: bool, \
        clips_to_surface_bounds: bool) -> Vector2:
    var point_on_surface: Vector2 = \
            Gs.geometry.project_point_onto_surface(target_point, surface)
    self.target_projection_onto_surface = point_on_surface
    
    var is_surface_horizontal = \
            surface.side == SurfaceSide.FLOOR or \
            surface.side == SurfaceSide.CEILING
    var distance_to_center := \
            collider_half_width_height.y if \
            is_surface_horizontal else \
            collider_half_width_height.x
    var target_offset_from_surface := \
            distance_to_center * surface.normal if \
                    offsets_target_by_half_width_height else \
                    Vector2.ZERO
    
    if clips_to_surface_bounds:
        return point_on_surface + target_offset_from_surface
    else:
        if is_surface_horizontal:
            return Vector2(target_point.x, point_on_surface.y) + \
                    target_offset_from_surface
        else:
            return Vector2(point_on_surface.x, target_point.y) + \
                    target_offset_from_surface

func to_string() -> String:
    return "PositionAlongSurface{ %s, %s }" % [ \
            target_point, \
            surface.to_string() if \
                    surface != null else \
                    "NULL SURFACE", \
        ]

func _get_side() -> int:
    return surface.side if \
            surface != null else \
            SurfaceSide.NONE

static func copy( \
        destination: PositionAlongSurface, \
        source: PositionAlongSurface) -> void:
    destination.surface = source.surface
    destination.target_point = source.target_point
    destination.target_projection_onto_surface = \
            source.target_projection_onto_surface

func load_from_json_object( \
        json_object: Dictionary, \
        context: Dictionary) -> void:
    surface = context.id_to_surface[int(json_object.s)]
    target_point = Gs.utils.decode_vector2(json_object.t)
    target_projection_onto_surface = Gs.utils.decode_vector2(json_object.p)

func to_json_object() -> Dictionary:
    return {
        s = surface.get_instance_id(),
        t = Gs.utils.encode_vector2(target_point),
        p = Gs.utils.encode_vector2(target_projection_onto_surface),
    }
