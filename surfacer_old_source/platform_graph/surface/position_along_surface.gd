class_name PositionAlongSurface
extends Reference
## -   Represents a position along a surface.[br]
## -   Rather than considering polyline length, this only specifies the position
##     along the axis the surface is aligned to.[br]
## -   The position always indicates the center of the character's bounding
##     box.[br]


var surface: Surface

# An approximation for the center of the character's collision boundary
# corresponding to this position on the surface.
var target_point := Vector2.INF

# Used for debugging. May not always be set.
var target_projection_onto_surface := Vector2.INF

var side: int setget ,_get_side

var is_valid: bool setget ,_get_is_valid


func _init(position_to_copy = null) -> void:
    if position_to_copy != null:
        copy(self, position_to_copy)


func reset() -> void:
    self.surface = null
    self.target_point = Vector2.INF
    self.target_projection_onto_surface = Vector2.INF


func match_current_grab(
        surface: Surface,
        character_center: Vector2) -> void:
    self.surface = surface
    self.target_point = character_center
    self.target_projection_onto_surface = Vector2.INF
    if surface != null and \
            target_point != Vector2.INF:
        update_target_projection_onto_surface()


func match_surface_target_and_collider(
        surface: Surface,
        target_point: Vector2,
        collider: RotatedShape,
        clips_to_surface_bounds := false,
        matches_target_to_character_dimensions := true,
        rejects_non_overlapping_results := true) -> void:
    self.surface = surface
    _clip_and_project_target_point_for_center_of_collider(
            surface,
            target_point,
            collider,
            clips_to_surface_bounds,
            matches_target_to_character_dimensions,
            rejects_non_overlapping_results)


func update_target_projection_onto_surface() -> void:
    self.target_projection_onto_surface = \
            Sc.geometry.project_point_onto_surface(target_point, surface)


func _clip_and_project_target_point_for_center_of_collider(
        surface: Surface,
        target_point: Vector2,
        collider: RotatedShape,
        clips_to_surface_bounds: bool,
        matches_target_to_character_dimensions: bool,
        rejects_non_overlapping_results: bool) -> void:
    self.target_projection_onto_surface = \
            Sc.geometry.project_point_onto_surface(target_point, surface)
    
    var is_surface_horizontal = \
            surface.side == SurfaceSide.FLOOR or \
            surface.side == SurfaceSide.CEILING
    
    if clips_to_surface_bounds:
        if is_surface_horizontal:
            target_point.x = self.target_projection_onto_surface.x
        else:
            target_point.y = self.target_projection_onto_surface.y
    
    if matches_target_to_character_dimensions:
        target_point = Sc.geometry \
                .project_shape_onto_segment_and_away_from_concave_neighbors(
                        target_point,
                        collider,
                        surface,
                        true,
                        rejects_non_overlapping_results)
        self.target_projection_onto_surface = \
                Sc.geometry.project_point_onto_surface(target_point, surface)
    else:
        # Use the given target point as-is.
        pass
    
    self.target_point = target_point


func to_string(
        verbose := true,
        includes_projection := false) -> String:
    if verbose:
        var projection_str: String = \
                ", %s" % target_projection_onto_surface if \
                includes_projection else \
                ""
        return (
            "PositionAlongSurface{ %s%s, %s }"
        ) % [
            target_point,
            projection_str,
            surface.to_string(verbose) if \
                    is_instance_valid(surface) else \
                    "NULL SURFACE",
        ]
    else:
        var projection_str: String = \
                ", %s" % Sc.utils.get_vector_string(
                        target_projection_onto_surface, 1) if \
                includes_projection else \
                ""
        return "P{%s%s, %s}" % [
            Sc.utils.get_vector_string(target_point, 1),
            projection_str,
            surface.to_string(verbose) if \
                    is_instance_valid(surface) else \
                    "NULL",
        ]


func _get_side() -> int:
    return surface.side if \
            surface != null else \
            SurfaceSide.NONE


func _get_is_valid() -> bool:
    return !is_inf(target_point.x) and !is_inf(target_point.y)


static func copy(
        destination: PositionAlongSurface,
        source: PositionAlongSurface) -> void:
    destination.surface = source.surface
    destination.target_point = source.target_point
    destination.target_projection_onto_surface = \
            source.target_projection_onto_surface


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    surface = context.id_to_surface[int(json_object.s)]
    target_point = Sc.json.decode_vector2(json_object.t)
    target_projection_onto_surface = Sc.json.decode_vector2(json_object.p)


func to_json_object() -> Dictionary:
    return {
        s = surface.get_instance_id(),
        t = Sc.json.encode_vector2(target_point),
        p = Sc.json.encode_vector2(target_projection_onto_surface),
    }
