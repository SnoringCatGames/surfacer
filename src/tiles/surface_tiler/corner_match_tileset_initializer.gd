tool
class_name CornerMatchTilesetInitializer
extends Node


func initialize_tiles(tile_set: CornerMatchTileset) -> void:
    var corner_type_annotation_key: Dictionary = \
            Su.subtile_manifest.tile_set_image_parser \
                .parse_corner_type_annotation_key(
                    Su.subtile_manifest.corner_type_annotation_key_path,
                    Su.subtile_manifest.quadrant_size)
    tile_set.subtile_corner_types = Su.subtile_manifest.tile_set_image_parser \
            .parse_tile_set_corner_type_annotations(
                corner_type_annotation_key,
                Su.subtile_manifest.corner_types_to_swap_for_bottom_quadrants,
                Su.subtile_manifest.tile_set_corner_type_annotations_path,
                Su.subtile_manifest.quadrant_size)
    
    var shapes: Dictionary = Su.subtile_manifest.shape_calculator \
            .create_shapes_for_quadrants(tile_set)
    # Dictionary<CornerDirection, Dictionary<SubtileCorner, Shape2D>>
    var collision_shapes: Dictionary = shapes.collision_shapes
    # Dictionary<CornerDirection, Dictionary<SubtileCorner, OccluderPolygon2D>>
    var occlusion_shapes: Dictionary = shapes.occlusion_shapes
    
    _initialize_tile(
            tile_set,
            CellAngleType.A90,
            collision_shapes,
            occlusion_shapes)
    if Su.subtile_manifest.are_45_degree_subtiles_used:
        _initialize_tile(
                tile_set,
                CellAngleType.A45,
                collision_shapes,
                occlusion_shapes)
    if Su.subtile_manifest.are_27_degree_subtiles_used:
        _initialize_tile(
                tile_set,
                CellAngleType.A27,
                collision_shapes,
                occlusion_shapes)


func _initialize_tile(
        tile_set: CornerMatchTileset,
        angle_type: int,
        collision_shapes: Dictionary,
        occlusion_shapes: Dictionary) -> void:
    var tile_name_suffix: String
    match angle_type:
        CellAngleType.A90:
            tile_name_suffix = "90"
        CellAngleType.A45:
            tile_name_suffix = "45"
        CellAngleType.A27:
            tile_name_suffix = "27"
        _:
            Sc.logger.error("CornerMatchTilesetInitializer._initialize_tile")
    
    var tile_name: String = \
            Su.subtile_manifest.autotile_name_prefix + tile_name_suffix
    var tile_id := tile_set.find_tile_by_name(tile_name)
    if tile_id < 0:
        tile_id = tile_set.get_last_unused_tile_id()
        tile_set.create_tile(tile_id)
    
    var quadrants_texture_size: Vector2 = \
            Su.subtile_manifest.tile_set_quadrants_texture.get_size()
    var tile_region := Rect2(Vector2.ZERO, quadrants_texture_size)
    
    var subtile_size: Vector2 = \
            Vector2.ONE * Su.subtile_manifest.quadrant_size * 2
    
    tile_set.tile_set_name(tile_id, tile_name)
    tile_set.tile_set_texture(tile_id, Su.subtile_manifest.tile_set_quadrants_texture)
    tile_set.tile_set_region(tile_id, tile_region)
    tile_set.tile_set_tile_mode(tile_id, TileSet.AUTO_TILE)
    tile_set.autotile_set_size(tile_id, subtile_size)
    tile_set.autotile_set_bitmask_mode(tile_id, TileSet.BITMASK_3X3_MINIMAL)
    
    _tile_set_icon_coordinate(
            tile_set,
            tile_id)
    _tile_set_shapes_for_quadrants(
            tile_set,
            tile_id,
            collision_shapes,
            occlusion_shapes)


func _tile_set_icon_coordinate(
        tile_set: CornerMatchTileset,
        tile_id: int) -> void:
    # FIXME: LEFT OFF HERE: ----------------------------
#    autotile_set_icon_coordinate(tile_id, )
    pass


func _tile_set_shapes_for_quadrants(
        tile_set: CornerMatchTileset,
        tile_id: int,
        collision_shapes: Dictionary,
        occlusion_shapes: Dictionary) -> void:
    for corner_direction in tile_set.subtile_corner_types:
        var corner_types_flag_to_position: Dictionary = \
                tile_set.subtile_corner_types[corner_direction]
        for corner_types_flag in corner_types_flag_to_position:
            var quadrant_position: Vector2 = \
                    corner_types_flag_to_position[corner_types_flag]
            var corner_type: int = Su.subtile_manifest.tile_set_image_parser \
                    .get_corner_types_from_flag(corner_types_flag) \
                    .self_corner_type
            _set_shapes_for_quadrant(
                    tile_set,
                    tile_id,
                    quadrant_position,
                    corner_type,
                    corner_direction,
                    collision_shapes,
                    occlusion_shapes)


func _set_shapes_for_quadrant(
        tile_set: CornerMatchTileset,
        tile_id: int,
        quadrant_position: Vector2,
        corner_type: int,
        corner_direction: int,
        collision_shapes: Dictionary,
        occlusion_shapes: Dictionary) -> void:
    var collision_shape: Shape2D = \
            collision_shapes[corner_direction][corner_type]
    var occlusion_shape: OccluderPolygon2D = \
            occlusion_shapes[corner_direction][corner_type]
    if is_instance_valid(collision_shape):
        tile_set.tile_add_shape(
                tile_id,
                collision_shape,
                Transform2D.IDENTITY,
                false,
                quadrant_position)
        tile_set.autotile_set_light_occluder(
                tile_id,
                occlusion_shape,
                quadrant_position)
