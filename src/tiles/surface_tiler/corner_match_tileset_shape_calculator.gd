tool
class_name CornerMatchTilesetShapeCalculator
extends Node


func create_shapes_for_quadrants(tile_set: CornerMatchTileset) -> Dictionary:
    # FIXME: Dedup shape instances.
    
    var collision_shapes := {
        tl = {},
        tr = {},
        bl = {},
        br = {},
    }
    var occlusion_shapes := {
        tl = {},
        tr = {},
        bl = {},
        br = {},
    }
    
    for corner_direction in tile_set.subtile_corner_types:
        var corner_types_flag_to_position: Dictionary = \
                tile_set.subtile_corner_types[corner_direction]
        var is_top: bool = corner_direction.begins_with("t")
        var is_left: bool = corner_direction.ends_with("l")
        for corner_types_flag in corner_types_flag_to_position:
            var corner_type: int = Su.subtile_manifest.tile_set_image_parser \
                    .get_corner_types_from_flag(corner_types_flag) \
                    .self_corner_type
            _create_shapes_for_quadrant(
                    collision_shapes,
                    occlusion_shapes,
                    corner_type,
                    is_top,
                    is_left)
    
    return {
        collision_shapes = collision_shapes,
        occlusion_shapes = occlusion_shapes,
    }


func _create_shapes_for_quadrant(
        collision_shapes: Dictionary,
        occlusion_shapes: Dictionary,
        corner_type: int,
        is_top: bool,
        is_left: bool) -> void:
    var points := _get_shape_vertices_for_quadrant(
            corner_type,
            is_top,
            is_left)
    
    var collision_shape: Shape2D
    var occlusion_shape: OccluderPolygon2D
    
    if !points.empty():
        var points_pool := PoolVector2Array(points)
        
        if Su.subtile_manifest.forces_convex_collision_shapes or \
                Su.subtile_manifest.subtile_collision_margin == 0.0:
            collision_shape = ConvexPolygonShape2D.new()
            collision_shape.points = points_pool
        else:
            collision_shape = ConcavePolygonShape2D.new()
            collision_shape.segments = points_pool
        
        occlusion_shape = OccluderPolygon2D.new()
        occlusion_shape.polygon = points_pool
    
    var corner_key := ("t" if is_top else "b") + ("l" if is_left else "r")
    collision_shapes[corner_key][corner_type] = collision_shape
    occlusion_shapes[corner_key][corner_type] = occlusion_shape


func _get_shape_vertices_for_quadrant(
        corner_type: int,
        is_top: bool,
        is_left: bool) -> Array:
    var points := _get_shape_vertices_for_corner_type_at_top_left(corner_type)
    assert(points.size() % 2 == 0)
    
    # Flip vertically if needed.
    if !is_top:
        for vertex_index in points.size() / 2:
            var coordinate_index: int = vertex_index * 2 + 1
            points[coordinate_index] = \
                    Su.subtile_manifest.quadrant_size - points[coordinate_index]
    
    # Flip horizontally if needed.
    if !is_left:
        for vertex_index in points.size() / 2:
            var coordinate_index: int = vertex_index * 2
            points[coordinate_index] = \
                    Su.subtile_manifest.quadrant_size - points[coordinate_index]
    
    return points


func _get_shape_vertices_for_corner_type_at_top_left(corner_type: int) -> Array:
    var quadrant_size: int = Su.subtile_manifest.quadrant_size
    var collision_margin: float = Su.subtile_manifest.subtile_collision_margin
    
    match corner_type:
        SubtileCorner.EMPTY:
            return []
        SubtileCorner.FULLY_INTERIOR:
            return [
                0, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        SubtileCorner.ERROR:
            return [
                0, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        
        ### 90-degree.
        
        SubtileCorner.EXT_90H:
            return [
                0, collision_margin,
                quadrant_size, collision_margin,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        SubtileCorner.EXT_90V:
            return [
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                collision_margin, quadrant_size,
            ]
        SubtileCorner.EXT_90_90_CONVEX:
            return [
                collision_margin, collision_margin,
                quadrant_size, collision_margin,
                quadrant_size, quadrant_size,
                collision_margin, quadrant_size,
            ]
        SubtileCorner.EXT_90_90_CONCAVE:
            return [
                0, collision_margin,
                collision_margin, collision_margin,
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        
        SubtileCorner.EXT_INT_90H, \
        SubtileCorner.EXT_INT_90V, \
        SubtileCorner.EXT_INT_90_90_CONVEX, \
        SubtileCorner.EXT_INT_90_90_CONCAVE, \
        SubtileCorner.INT_90H, \
        SubtileCorner.INT_90V, \
        SubtileCorner.INT_90_90_CONVEX, \
        SubtileCorner.INT_90_90_CONCAVE:
            return [
                0, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        
        ### 45-degree.
        
        SubtileCorner.EXT_45_FLOOR:
            return [
                0, collision_margin,
                quadrant_size - collision_margin, quadrant_size,
                0, quadrant_size,
            ]
        SubtileCorner.EXT_45_CEILING:
            return [
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size - collision_margin,
            ]
        SubtileCorner.EXT_EXT_45_CLIPPED:
            return [
                0, collision_margin,
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        
        SubtileCorner.EXT_INT_45_FLOOR, \
        SubtileCorner.EXT_INT_45_CEILING, \
        SubtileCorner.EXT_INT_45_CLIPPED, \
        SubtileCorner.INT_EXT_45_CLIPPED, \
        SubtileCorner.INT_45_FLOOR, \
        SubtileCorner.INT_45_CEILING, \
        SubtileCorner.INT_INT_45_CLIPPED:
            return [
                0, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        
        ### 90-to-45-degree.
        
        SubtileCorner.EXT_90H_45_CONVEX_ACUTE:
            return [
                collision_margin * 2, collision_margin,
                quadrant_size, collision_margin,
                quadrant_size, quadrant_size - collision_margin,
            ]
        SubtileCorner.EXT_90V_45_CONVEX_ACUTE:
            return [
                collision_margin, collision_margin * 2,
                quadrant_size - collision_margin, quadrant_size,
                collision_margin, quadrant_size,
            ]
        
        SubtileCorner.EXT_90H_45_CONVEX:
            return [
                0, collision_margin,
                quadrant_size, collision_margin,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        SubtileCorner.EXT_90V_45_CONVEX:
            return [
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                collision_margin, quadrant_size,
            ]
        
        SubtileCorner.EXT_90H_45_CONCAVE:
            return [
                0, collision_margin,
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        SubtileCorner.EXT_90V_45_CONCAVE:
            return [
                0, collision_margin,
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        
        SubtileCorner.EXT_INT_90H_45_CONVEX, \
        SubtileCorner.EXT_INT_90V_45_CONVEX, \
        SubtileCorner.EXT_INT_90H_45_CONCAVE, \
        SubtileCorner.EXT_INT_90V_45_CONCAVE, \
        SubtileCorner.INT_EXT_90H_45_CONCAVE, \
        SubtileCorner.INT_EXT_90V_45_CONCAVE, \
        SubtileCorner.INT_INT_90H_45_CONCAVE, \
        SubtileCorner.INT_INT_90V_45_CONCAVE:
            return [
                0, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        
        ### Complex 90-45-degree combinations.
        
        SubtileCorner.EXT_INT_45_FLOOR_45_CEILING, \
        SubtileCorner.INT_45_FLOOR_45_CEILING, \
        SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE, \
        SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE, \
        SubtileCorner.INT_90H_EXT_INT_45_CONVEX_ACUTE, \
        SubtileCorner.INT_90V_EXT_INT_45_CONVEX_ACUTE, \
        SubtileCorner.INT_90H_EXT_INT_90H_45_CONCAVE, \
        SubtileCorner.INT_90V_EXT_INT_90V_45_CONCAVE, \
        SubtileCorner.INT_90H_INT_EXT_45_CLIPPED, \
        SubtileCorner.INT_90V_INT_EXT_45_CLIPPED, \
        SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED, \
        SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE, \
        SubtileCorner.INT_INT_90H_45_CONCAVE_INT_45_CEILING, \
        SubtileCorner.INT_INT_90V_45_CONCAVE_INT_45_FLOOR, \
        SubtileCorner.INT_90H_INT_INT_90V_45_CONCAVE, \
        SubtileCorner.INT_90V_INT_INT_90H_45_CONCAVE, \
        SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR, \
        SubtileCorner.INT_90_90_CONCAVE_INT_45_CEILING, \
        SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR_45_CEILING, \
        SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE, \
        SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE, \
        SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_90V_45_CONCAVE, \
        SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_INT_45_CEILING, \
        SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE_INT_45_FLOOR:
            return [
                0, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        
        # FIXME: LEFT OFF HERE: -------- A27
        
        SubtileCorner.UNKNOWN, \
        _:
            # FIXME: LEFT OFF HERE: ---------------------
            # - Translate int to String after moving the translator to manifest.
            Sc.logger.error(
                    "CornerMatchTilesetShapeCalculator" +
                    "._get_shape_vertices_for_corner_type_at_top_left: %s" % \
                    corner_type)
            return [
                0, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
