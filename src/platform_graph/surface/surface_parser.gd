class_name SurfaceParser
extends Reference


# TODO: Map the TileMap into an RTree or QuadTree.

const SURFACES_TILE_MAPS_COLLISION_LAYER := 1

const CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET := 0.02
const CORNER_TARGET_MORE_PREFERRED_SURFACE_SIDE_OFFSET := 0.01

# TODO: We might want to instead replace this with a ratio (like 1.1) of the
#       KinematicBody2D.get_safe_margin value (defaults to 0.08, but we set it
#       higher during graph calculations).
const _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD := 0.5

const _EQUAL_POINT_EPSILON := 0.1


func parse(
        surface_store: SurfaceStore,
        tilemaps: Array,
        surface_marks: Array) -> void:
    _validate_tilemap_collection(tilemaps)
    
    # Record the maximum cell size and combined region from all tile maps.
    _calculate_max_tilemap_cell_size(surface_store, tilemaps)
    _calculate_combined_tilemap_rect(surface_store, tilemaps)
    
    for tile_map in tilemaps:
        _parse_tilemap(surface_store, tile_map)
    
    for mark in surface_marks:
        _parse_surface_mark(surface_store, mark, tilemaps[0])
    surface_store.marks = surface_marks


func _validate_tilemap_collection(tilemaps: Array) -> void:
    assert(!tilemaps.empty(),
            "Collidable TileMap collection must not be empty.")
    # FIXME: -------------------
    # - Maybe just print a warning that surfaces from multiple tilemaps won't
    #   be merged?
    # TODO: Add support for more than one collidable TileMap.
#    assert(tilemaps.size() == 1,
#            "Surfacer currently does not support multiple collidable " +
#            "Tilemaps per level.")
    var cell_size: Vector2 = tilemaps[0].cell_size
    assert(cell_size == Sc.level_session.config.cell_size,
            "TileMap.cell_size does not match level config.")
    for tile_map in tilemaps:
        # FIXME: -------------------
        # - Inner tilemaps are half size...
#        assert(tile_map.cell_size == cell_size,
#                "All collidable Tilemaps must use the same cell size.")
        assert(tile_map.position == Vector2.ZERO,
                "Tilemaps must be positioned at (0,0).")
        assert(tile_map is SurfacesTilemap or \
                tile_map is CornerMatchInnerTilemap)


func _calculate_max_tilemap_cell_size(
        surface_store: SurfaceStore,
        tilemaps: Array) -> void:
    var max_tilemap_cell_size := Vector2.ZERO
    for tile_map in tilemaps:
        if tile_map.cell_size.x + tile_map.cell_size.y > \
                max_tilemap_cell_size.x + max_tilemap_cell_size.y:
            max_tilemap_cell_size = tile_map.cell_size
    surface_store.max_tilemap_cell_size = max_tilemap_cell_size


func _calculate_combined_tilemap_rect(
        surface_store: SurfaceStore,
        tilemaps: Array) -> void:
    var combined_tilemap_rect: Rect2 = \
            Sc.geometry.get_tilemap_bounds_in_world_coordinates(tilemaps[0])
    for tile_map in tilemaps:
        combined_tilemap_rect = combined_tilemap_rect.merge(
                Sc.geometry.get_tilemap_bounds_in_world_coordinates(tile_map))
    surface_store.combined_tilemap_rect = combined_tilemap_rect


# Parses the given TileMap into a set of nodes for the platform graph.
# 
# - Each "connecting" tile from the TileMap will be merged into a single
#   surface node in the graph.
# - Each node in this graph corresponds to a continuous surface that could be
#   walked on or climbed on (i.e., floors and walls).
# - Each edge in this graph corresponds to a possible movement that the
#   character could take to get from one surface to another.
# 
# Assumptions:
# - The given TileMap only uses collidable tiles. Use a separate TileMap to
#   paint any non-collidable tiles.
# - The given TileMap only uses tiles with convex collision boundaries.
func _parse_tilemap(
        surface_store: SurfaceStore,
        tile_map: SurfacesTilemap) -> void:
    Sc.profiler.start("validate_tileset")
    _validate_tileset(tile_map)
    Sc.profiler.stop("validate_tileset")
    
    Sc.profiler.start("parse_tileset")
    var tile_id_to_coord_to_shape_data := _parse_tileset(tile_map)
    Sc.profiler.stop("parse_tileset")
    
    Sc.profiler.start("parse_tilemap_cells_into_surfaces")
    var tilemap_index_to_floor := {}
    var tilemap_index_to_left_wall := {}
    var tilemap_index_to_right_wall := {}
    var tilemap_index_to_ceiling := {}
    _parse_tilemap_cells_into_surfaces(
            tilemap_index_to_floor,
            tilemap_index_to_left_wall,
            tilemap_index_to_right_wall,
            tilemap_index_to_ceiling,
            tile_id_to_coord_to_shape_data,
            tile_map)
    Sc.profiler.stop("parse_tilemap_cells_into_surfaces")
    
    Sc.profiler.start("remove_internal_surfaces")
    _remove_internal_surfaces(
            tilemap_index_to_floor,
            tilemap_index_to_left_wall,
            tilemap_index_to_right_wall,
            tilemap_index_to_ceiling,
            tile_id_to_coord_to_shape_data,
            tile_map)
    Sc.profiler.stop("remove_internal_surfaces")
    
    Sc.profiler.start("merge_continuous_surfaces")
    _merge_continuous_surfaces(
            tilemap_index_to_floor,
            tilemap_index_to_left_wall,
            tilemap_index_to_right_wall,
            tilemap_index_to_ceiling,
            tile_map)
    Sc.profiler.stop("merge_continuous_surfaces")
    
    Sc.profiler.start("get_surface_list_from_map")
    var floors := _get_surface_list_from_map(tilemap_index_to_floor)
    var ceilings := _get_surface_list_from_map(tilemap_index_to_ceiling)
    var left_walls := _get_surface_list_from_map(tilemap_index_to_left_wall)
    var right_walls := _get_surface_list_from_map(tilemap_index_to_right_wall)
    Sc.profiler.stop("get_surface_list_from_map")
    
    Sc.profiler.start("remove_internal_collinear_vertices_duration")
    _remove_internal_collinear_vertices(floors)
    _remove_internal_collinear_vertices(ceilings)
    _remove_internal_collinear_vertices(left_walls)
    _remove_internal_collinear_vertices(right_walls)
    Sc.profiler.stop("remove_internal_collinear_vertices_duration")
    
    Sc.profiler.start("store_surfaces_duration")
    _store_surfaces(
            surface_store,
            tile_map,
            floors,
            ceilings,
            left_walls,
            right_walls)
    Sc.profiler.stop("store_surfaces_duration")
    
    Sc.profiler.start("populate_derivative_collections")
    _populate_derivative_collections(surface_store, tile_map)
    Sc.profiler.stop("populate_derivative_collections")
    
    Sc.profiler.start("assign_neighbor_surfaces_duration")
    _assign_neighbor_surfaces(
            surface_store.floors,
            surface_store.ceilings,
            surface_store.left_walls,
            surface_store.right_walls)
    Sc.profiler.stop("assign_neighbor_surfaces_duration")
    
    Sc.profiler.start("_assert_surfaces_have_neighbors")
    _assert_surfaces_have_neighbors(surface_store.floors)
    _assert_surfaces_have_neighbors(surface_store.ceilings)
    _assert_surfaces_have_neighbors(surface_store.left_walls)
    _assert_surfaces_have_neighbors(surface_store.right_walls)
    Sc.profiler.stop("_assert_surfaces_have_neighbors")
    
    Sc.profiler.start("calculate_shape_bounding_boxes_for_surfaces_duration")
    # Since this calculation will loop around transitive neigbors, and since
    # every surface should be connected transitively to a floor, it should also
    # end up recording the bounding box for all other surface sides too.
    _calculate_shape_bounding_boxes_for_surfaces(surface_store.floors)
    Sc.profiler.stop("calculate_shape_bounding_boxes_for_surfaces_duration")


func _store_surfaces(
        surface_store: SurfaceStore,
        tile_map: SurfacesTilemap,
        floors: Array,
        ceilings: Array,
        left_walls: Array,
        right_walls: Array) -> void:
    _populate_surface_objects(
            floors,
            SurfaceSide.FLOOR)
    _populate_surface_objects(
            ceilings,
            SurfaceSide.CEILING)
    _populate_surface_objects(
            left_walls,
            SurfaceSide.LEFT_WALL)
    _populate_surface_objects(
            right_walls,
            SurfaceSide.RIGHT_WALL)
    
    _copy_surfaces_to_main_collection(
            floors,
            surface_store.floors)
    _copy_surfaces_to_main_collection(
            ceilings,
            surface_store.ceilings)
    _copy_surfaces_to_main_collection(
            left_walls,
            surface_store.left_walls)
    _copy_surfaces_to_main_collection(
            right_walls,
            surface_store.right_walls)
    
    _free_objects(floors)
    _free_objects(ceilings)
    _free_objects(left_walls)
    _free_objects(right_walls)


func _populate_derivative_collections(
        surface_store: SurfaceStore,
        tile_map: SurfacesTilemap) -> void:
    # TODO: This is broken with multiple tilemaps.
    surface_store.all_surfaces = []
    Sc.utils.concat(
            surface_store.all_surfaces,
            surface_store.floors)
    Sc.utils.concat(
            surface_store.all_surfaces,
            surface_store.right_walls)
    Sc.utils.concat(
            surface_store.all_surfaces,
            surface_store.left_walls)
    Sc.utils.concat(
            surface_store.all_surfaces,
            surface_store.ceilings)
    surface_store.non_ceiling_surfaces = []
    Sc.utils.concat(
            surface_store.non_ceiling_surfaces,
            surface_store.floors)
    Sc.utils.concat(
            surface_store.non_ceiling_surfaces,
            surface_store.right_walls)
    Sc.utils.concat(
            surface_store.non_ceiling_surfaces,
            surface_store.left_walls)
    surface_store.non_floor_surfaces = []
    Sc.utils.concat(
            surface_store.non_floor_surfaces,
            surface_store.right_walls)
    Sc.utils.concat(
            surface_store.non_floor_surfaces,
            surface_store.left_walls)
    Sc.utils.concat(
            surface_store.non_floor_surfaces,
            surface_store.ceilings)
    surface_store.non_wall_surfaces = []
    Sc.utils.concat(
            surface_store.non_wall_surfaces,
            surface_store.floors)
    Sc.utils.concat(
            surface_store.non_wall_surfaces,
            surface_store.ceilings)
    surface_store.all_walls = []
    Sc.utils.concat(
            surface_store.all_walls,
            surface_store.right_walls)
    Sc.utils.concat(
            surface_store.all_walls,
            surface_store.left_walls)
    
    var floor_mapping = \
            _create_tilemap_mapping_from_surfaces(surface_store.floors)
    var ceiling_mapping = \
            _create_tilemap_mapping_from_surfaces(surface_store.ceilings)
    var left_wall_mapping = \
            _create_tilemap_mapping_from_surfaces(surface_store.left_walls)
    var right_wall_mapping = \
            _create_tilemap_mapping_from_surfaces(surface_store.right_walls)
    
    surface_store._tilemap_index_to_surface_maps[tile_map] = {
        SurfaceSide.FLOOR: floor_mapping,
        SurfaceSide.CEILING: ceiling_mapping,
        SurfaceSide.LEFT_WALL: left_wall_mapping,
        SurfaceSide.RIGHT_WALL: right_wall_mapping,
    }


static func _validate_tileset(tile_map: SurfacesTilemap) -> void:
    var cell_size := tile_map.cell_size
    
    var tile_set: SurfacesTileset = tile_map.tile_set
    assert(is_instance_valid(tile_set))
    assert(tile_set is SurfacesTileset,
            "Tilesets attached to a collidable TileMap must be assigned " +
            "a script that extends SurfacesTileset.")
    
    var ids: Array = tile_set.get_collidable_tiles_ids()
    assert(ids.size() > 0)
    
    for tile_id in ids:
        var tile_name := tile_set.tile_get_name(tile_id)
        assert(is_instance_valid(tile_set.get_tile_properties(tile_name)),
                ("Tile ID is not recognized by " +
                "SurfacesTileset.get_tile_properties: %s") % tile_name)
        
        var shapes := tile_set.tile_get_shapes(tile_id)
        for shape_data in shapes:
            var shape: Shape2D = shape_data.shape
            var shape_transform: Transform2D = shape_data.shape_transform
            var points: PoolVector2Array = shape.points
            
            assert(shape is ConvexPolygonShape2D,
                    "TileSet collision shapes must be of type " +
                    "ConvexPolygonShape2D.")
            
            for i in points.size() - 1:
                assert(points[i] != points[i + 1],
                        "TileSet collision shapes must not have " +
                        "duplicated vertices.")
            assert(points[0] != points[points.size() - 1],
                    "TileSet collision shapes must not have " +
                    "duplicated vertices.")
            
            if points.size() >= 3:
                var previous_point: Vector2 = points[points.size() - 2]
                var current_point: Vector2 = points[points.size() - 1]
                for next_point in points:
                    assert(!Sc.geometry.are_points_collinear(
                                previous_point,
                                current_point,
                                next_point,
                                0.001),
                            "TileSet collision-shape vertices must not be " +
                            "collinear.")
                    previous_point = current_point
                    current_point = next_point
            
            for i in points.size():
                assert(points[i].x == int(points[i].x) and \
                        points[i].y == int(points[i].y), 
                        "TileSet collision-shape vertices must align with " +
                        "whole-pixel coordinates (this is important for " +
                        "merging adjacent-tile surfaces).")
            
            if !Su.are_oddly_shaped_surfaces_used:
                for i in points.size():
                    var point: Vector2 = points[i]
                    assert(Sc.geometry.are_points_equal_with_epsilon(
                                    point, Vector2(0.0, 0.0)) or \
                            Sc.geometry.are_points_equal_with_epsilon(
                                    point, Vector2(0.0, cell_size.y)) or \
                            Sc.geometry.are_points_equal_with_epsilon(
                                    point, Vector2(cell_size.x, 0.0)) or \
                            Sc.geometry.are_points_equal_with_epsilon(
                                    point, Vector2(cell_size.x, cell_size.y)),
                            "Oddly-shaped tiles aren't enabled " + 
                            "(Su.are_oddly_shaped_surfaces_used).")
            
            assert(Sc.geometry.is_polygon_convex(points, 0.01),
                    "TileSet collision shapes must be convex.")
            
            for point in points:
                assert(point.x >= 0.0 and \
                        point.y >= 0.0 and \
                        point.x <= cell_size.x and \
                        point.y <= cell_size.y,
                        "TileSet collision-shape vertices must not exceed " +
                        "the cell-size of the corresponding TileMap.")


static func _parse_tileset(tile_map: SurfacesTilemap) -> Dictionary:
    var tile_set: SurfacesTileset = tile_map.tile_set
    var cell_size := tile_map.cell_size
    var tile_id_to_coord_to_shape_data := {}
    for tile_id in tile_set.get_collidable_tiles_ids():
        var tile_coord_to_shape := _parse_tile(
                tile_id,
                tile_set,
                cell_size)
        tile_id_to_coord_to_shape_data[tile_id] = tile_coord_to_shape
    return tile_id_to_coord_to_shape_data


# Parses the given tile.
# -   Each shape in the tile will be mapped by its coordinates within the tile.
static func _parse_tile(
        tile_id: int,
        tile_set: TileSet,
        cell_size: Vector2) -> Dictionary:
    var tile_coord_to_shape := {}
    var shapes := tile_set.tile_get_shapes(tile_id)
    for shape_data in shapes:
        tile_coord_to_shape[shape_data.autotile_coord] = _parse_tile_shape(
                shape_data.shape,
                shape_data.shape_transform,
                shape_data.one_way,
                cell_size)
    return tile_coord_to_shape


# Parses the given tile shape.
# -   The tile shape will be split into separate polylines corresponding to the
#     top-side, left-side, and right-side of the shape.
# -   Each of these polylines will be stored with their vertices in clockwise
#     order.
static func _parse_tile_shape(
        shape: Shape2D,
        shape_transform: Transform2D,
        is_one_way: bool,
        cell_size: Vector2) -> TileShapeData:
    
    # Transform tile shapes into world coordinates.
    # ConvexPolygonShape2D
    
    var vertex_count: int = shape.points.size()
    var vertices := Array()
    vertices.resize(vertex_count)
    for i in vertex_count:
        var vertex: Vector2 = shape.points[i]
        var vertex_world_coords: Vector2 = shape_transform.xform(vertex)
        vertices[i] = vertex_world_coords
    
    var is_clockwise: bool = Sc.geometry.is_polygon_clockwise(vertices)
    
    # Find the left-most, right-most, and bottom-most vertices.
    
    var left_most_vertex_x: float = vertices[0].x
    var right_most_vertex_x: float = vertices[0].x
    var bottom_most_vertex_y: float = vertices[0].y
    var top_most_vertex_y: float = vertices[0].y
    var left_most_vertex_index := 0
    var right_most_vertex_index := 0
    var bottom_most_vertex_index := 0
    var top_most_vertex_index := 0
    
    for i in range(1, vertex_count):
        var vertex: Vector2 = vertices[i]
        if vertex.x < left_most_vertex_x:
            left_most_vertex_x = vertex.x
            left_most_vertex_index = i
        if vertex.x > right_most_vertex_x:
            right_most_vertex_x = vertex.x
            right_most_vertex_index = i
        if vertex.y > bottom_most_vertex_y:
            bottom_most_vertex_y = vertex.y
            bottom_most_vertex_index = i
        if vertex.y < top_most_vertex_y:
            top_most_vertex_y = vertex.y
            top_most_vertex_index = i
    
    # Iterate across the edges in a clockwise direction, regardless of the
    # order the vertices are defined in.
    var step := 1 if is_clockwise else vertex_count - 1
    
    var i1: int
    var i2: int
    var v1 := Vector2.INF
    var v2 := Vector2.INF
    var pos_angle: float
    var is_wall_segment: bool
    
    var top_side_start_index: int
    var top_side_end_index: int
    var left_side_start_index: int
    var right_side_end_index: int
    
    # Find the start of the top-side.
    
    var FLOOR_MAX_ANGLE_BELOW_90: float = \
            Sc.geometry.FLOOR_MAX_ANGLE + Sc.geometry.WALL_ANGLE_EPSILON
    var FLOOR_MIN_ANGLE_ABOVE_90: float = \
            PI - Sc.geometry.FLOOR_MAX_ANGLE - Sc.geometry.WALL_ANGLE_EPSILON
    
    # Fence-post problem: Calculate the first segment.
    i1 = left_most_vertex_index
    i2 = (i1 + step) % vertex_count
    v1 = vertices[i1]
    v2 = vertices[i2]
    pos_angle = abs(v1.angle_to_point(v2))
    is_wall_segment = \
            pos_angle > FLOOR_MAX_ANGLE_BELOW_90 and \
            pos_angle < FLOOR_MIN_ANGLE_ABOVE_90
    
    # If we find a non-wall segment, that's the start of the top-side. If we
    # instead find no non-wall segments until one segment after the top-most
    # vertex, then there is no top-side, and we will treat the top-most vertex
    # as both the start and end of this degenerate-case "top-side".
    while is_wall_segment and i1 != top_most_vertex_index:
        i1 = i2
        i2 = (i1 + step) % vertex_count
        v1 = vertices[i1]
        v2 = vertices[i2]
        pos_angle = abs(v1.angle_to_point(v2))
        is_wall_segment = \
                pos_angle > FLOOR_MAX_ANGLE_BELOW_90 and \
                pos_angle < FLOOR_MIN_ANGLE_ABOVE_90
    
    top_side_start_index = i1
    
    # Find the end of the top-side.
    
    # If we find a wall segment, that's the end of the top-side. If we instead
    # find no wall segments until one segment after the right-most vertex, then
    # there is no right-side, and we will treat the right-most vertex as the
    # end of the top-side.
    while !is_wall_segment and i1 != right_most_vertex_index:
        i1 = i2
        i2 = (i1 + step) % vertex_count
        v1 = vertices[i1]
        v2 = vertices[i2]
        pos_angle = abs(v1.angle_to_point(v2))
        is_wall_segment = \
                pos_angle > FLOOR_MAX_ANGLE_BELOW_90 and \
                pos_angle < FLOOR_MIN_ANGLE_ABOVE_90
    
    top_side_end_index = i1
    
    # Find the end of the right-side.
    
    # If we find a non-wall segment, that's the end of the right-side. If we
    # instead find no non-wall segments until one segment after the bottom-most
    # vertex, then there is no bottom-side, and we will treat the bottom-most
    # vertex as end of the bottom-side.
    while is_wall_segment and i1 != bottom_most_vertex_index:
        i1 = i2
        i2 = (i1 + step) % vertex_count
        v1 = vertices[i1]
        v2 = vertices[i2]
        pos_angle = abs(v1.angle_to_point(v2))
        is_wall_segment = \
                pos_angle > FLOOR_MAX_ANGLE_BELOW_90 and \
                pos_angle < FLOOR_MIN_ANGLE_ABOVE_90
    
    right_side_end_index = i1
    
    # Find the start of the left-side.
    
    # If we find a wall segment, that's the start of the left-side. If we
    # instead find no wall segments until one segment after the left-most
    # vertex, then there is no left-side, and we will treat the left-most
    # vertex as both the start and end of this degenerate-case "left-side".
    while !is_wall_segment and i1 != left_most_vertex_index:
        i1 = i2
        i2 = (i1 + step) % vertex_count
        v1 = vertices[i1]
        v2 = vertices[i2]
        pos_angle = abs(v1.angle_to_point(v2))
        is_wall_segment = \
                pos_angle > FLOOR_MAX_ANGLE_BELOW_90 and \
                pos_angle < FLOOR_MIN_ANGLE_ABOVE_90
    
    left_side_start_index = i1
    
    var i: int
    
    # Calculate the polyline corresponding to the top side.
    
    var top_side_vertices := []
    i = top_side_start_index
    while i != top_side_end_index:
        top_side_vertices.push_back(vertices[i])
        i = (i + step) % vertex_count
    top_side_vertices.push_back(vertices[i])
    
    # Calculate the polyline corresponding to the bottom side.
    
    var bottom_side_vertices := []
    i = right_side_end_index
    while i != left_side_start_index:
        bottom_side_vertices.push_back(vertices[i])
        i = (i + step) % vertex_count
    bottom_side_vertices.push_back(vertices[i])
    
    # Calculate the polyline corresponding to the left side.
    
    var left_side_vertices := []
    i = left_side_start_index
    while i != top_side_start_index:
        left_side_vertices.push_back(vertices[i])
        i = (i + step) % vertex_count
    left_side_vertices.push_back(vertices[i])
    
    # Calculate the polyline corresponding to the right side.
    
    var right_side_vertices := []
    i = top_side_end_index
    while i != right_side_end_index:
        right_side_vertices.push_back(vertices[i])
        i = (i + step) % vertex_count
    right_side_vertices.push_back(vertices[i])
    
    var tile_shape_data := TileShapeData.new()
    tile_shape_data.top_vertices = top_side_vertices
    tile_shape_data.right_vertices = right_side_vertices
    tile_shape_data.bottom_vertices = bottom_side_vertices
    tile_shape_data.left_vertices = left_side_vertices
    tile_shape_data.is_top_axially_aligned = \
            _get_is_side_axially_aligned(top_side_vertices, true)
    tile_shape_data.is_right_axially_aligned = \
            _get_is_side_axially_aligned(right_side_vertices, true)
    tile_shape_data.is_bottom_axially_aligned = \
            _get_is_side_axially_aligned(bottom_side_vertices, true)
    tile_shape_data.is_left_axially_aligned = \
            _get_is_side_axially_aligned(left_side_vertices, true)
    tile_shape_data.is_top_along_cell_boundary = \
            _get_is_side_along_cell_boundary(
                top_side_vertices, true, cell_size)
    tile_shape_data.is_right_along_cell_boundary = \
            _get_is_side_along_cell_boundary(
                right_side_vertices, true, cell_size)
    tile_shape_data.is_bottom_along_cell_boundary = \
            _get_is_side_along_cell_boundary(
                bottom_side_vertices, true, cell_size)
    tile_shape_data.is_left_along_cell_boundary = \
            _get_is_side_along_cell_boundary(
                left_side_vertices, true, cell_size)
    
    return tile_shape_data


static func _get_is_side_axially_aligned(
        vertices: Array,
        is_horizontal: bool) -> bool:
    if vertices.size() == 1:
        return true
    elif vertices.size() == 2:
        if is_horizontal:
            return Sc.geometry.are_floats_equal_with_epsilon(
                    vertices[0].x, vertices[1].x)
        else:
            return Sc.geometry.are_floats_equal_with_epsilon(
                    vertices[0].y, vertices[1].y)
    return false


static func _get_is_side_along_cell_boundary(
        vertices: Array,
        is_horizontal: bool,
        cell_size: Vector2) -> bool:
    if !_get_is_side_axially_aligned(vertices, is_horizontal):
        return false
    var vertex: Vector2 = vertices[0]
    if is_horizontal:
        return Sc.geometry.are_floats_equal_with_epsilon(
                    vertex.y, 0.0) or \
                Sc.geometry.are_floats_equal_with_epsilon(
                    vertex.y, cell_size.y)
    else:
        return Sc.geometry.are_floats_equal_with_epsilon(
                    vertex.x, 0.0) or \
                Sc.geometry.are_floats_equal_with_epsilon(
                    vertex.x, cell_size.x)


static func _parse_tilemap_cells_into_surfaces(
        tilemap_index_to_floor: Dictionary,
        tilemap_index_to_left_wall: Dictionary,
        tilemap_index_to_right_wall: Dictionary,
        tilemap_index_to_ceiling: Dictionary,
        tile_id_to_coord_to_shape_data: Dictionary,
        tile_map: SurfacesTilemap) -> void:
    var cell_size := tile_map.cell_size
    var used_cells := tile_map.get_used_cells()
    var tile_set: SurfacesTileset = tile_map.tile_set
    
    for tilemap_position in used_cells:
        var cell_position_world_coords: Vector2 = tilemap_position * cell_size
        var tilemap_index: int = Sc.geometry.get_tilemap_index_from_grid_coord(
                    tilemap_position,
                    tile_map)
        var tile_id := tile_map.get_cellv(tilemap_position)
        
        if !tile_set.get_is_tile_collidable(tile_id):
            # Ignore non-collidable tiles.
            continue
        
        var tile_name := tile_set.tile_get_name(tile_id)
        var tile_coord := tile_map.get_cell_autotile_coord(
                tilemap_position.x, tilemap_position.y)
        var tile_shape_data: TileShapeData = \
                tile_id_to_coord_to_shape_data[tile_id][tile_coord]
        var surface_properties: SurfaceProperties = \
                tile_set.get_tile_properties(tile_name)
        
        # Transform tile shapes into world coordinates.
        var floor_vertices_world_coords := \
                tile_shape_data.top_vertices.duplicate()
        for i in floor_vertices_world_coords.size():
            floor_vertices_world_coords[i] += cell_position_world_coords
        var ceiling_vertices_world_coords := \
                tile_shape_data.bottom_vertices.duplicate()
        for i in ceiling_vertices_world_coords.size():
            ceiling_vertices_world_coords[i] += cell_position_world_coords
        var left_wall_vertices_world_coords := \
                tile_shape_data.right_vertices.duplicate()
        for i in left_wall_vertices_world_coords.size():
            left_wall_vertices_world_coords[i] += cell_position_world_coords
        var right_wall_vertices_world_coords := \
                tile_shape_data.left_vertices.duplicate()
        for i in right_wall_vertices_world_coords.size():
            right_wall_vertices_world_coords[i] += cell_position_world_coords
        
        # Store the surfaces.
        var floor_surface = _TmpSurface.new()
        floor_surface.vertices_array = floor_vertices_world_coords
        floor_surface.tile_map = tile_map
        floor_surface.tilemap_indices = [tilemap_index]
        floor_surface.properties = surface_properties
        var ceiling_surface = _TmpSurface.new()
        ceiling_surface.vertices_array = ceiling_vertices_world_coords
        ceiling_surface.tile_map = tile_map
        ceiling_surface.tilemap_indices = [tilemap_index]
        ceiling_surface.properties = surface_properties
        var left_wall_surface = _TmpSurface.new()
        left_wall_surface.vertices_array = left_wall_vertices_world_coords
        left_wall_surface.tile_map = tile_map
        left_wall_surface.tilemap_indices = [tilemap_index]
        left_wall_surface.properties = surface_properties
        var right_wall_surface = _TmpSurface.new()
        right_wall_surface.vertices_array = right_wall_vertices_world_coords
        right_wall_surface.tile_map = tile_map
        right_wall_surface.tilemap_indices = [tilemap_index]
        right_wall_surface.properties = surface_properties
        
        tilemap_index_to_floor[tilemap_index] = floor_surface
        tilemap_index_to_ceiling[tilemap_index] = ceiling_surface
        tilemap_index_to_left_wall[tilemap_index] = left_wall_surface
        tilemap_index_to_right_wall[tilemap_index] = right_wall_surface


# Removes some "internal" surfaces.
# 
# -   Specifically, this checks for pairs of floor+ceiling segments or
#     left-wall+right-wall segments that share the same vertices.
#     -   In this case, both segments in these pairs are considered internal,
#         and are removed.
# -   This also considers whether any single-vertex surfaces match any vertex
#     of an opposite-side surface.
#     -   In this case, the single-vertex surface is removed, and the
#         multi-vertex surface is kept.
# -   Partial-internal surfaces are truncated.
# -   Any surface polyline that consists of more than one segment is ignored.
static func _remove_internal_surfaces(
        tilemap_index_to_floor: Dictionary,
        tilemap_index_to_left_wall: Dictionary,
        tilemap_index_to_right_wall: Dictionary,
        tilemap_index_to_ceiling: Dictionary,
        tile_id_to_coord_to_shape_data: Dictionary,
        tile_map: TileMap) -> void:
    _remove_internal_single_vertex_surfaces(
            tilemap_index_to_floor,
            tilemap_index_to_left_wall,
            tilemap_index_to_right_wall,
            tilemap_index_to_ceiling,
            tile_id_to_coord_to_shape_data,
            tile_map)
    _remove_internal_multi_vertex_surfaces(
            tilemap_index_to_floor,
            tilemap_index_to_left_wall,
            tilemap_index_to_right_wall,
            tilemap_index_to_ceiling,
            tile_id_to_coord_to_shape_data,
            tile_map)


static func _remove_internal_single_vertex_surfaces(
        tilemap_index_to_floor: Dictionary,
        tilemap_index_to_left_wall: Dictionary,
        tilemap_index_to_right_wall: Dictionary,
        tilemap_index_to_ceiling: Dictionary,
        tile_id_to_coord_to_shape_data: Dictionary,
        tile_map: TileMap) -> void:
    var used_rect := tile_map.get_used_rect()
    var tilemap_row_count: int = used_rect.size.y
    var tilemap_column_count: int = used_rect.size.x
    
    for row in tilemap_row_count:
        for column in tilemap_column_count:
            var tilemap_index: int = row * tilemap_column_count + column
            
            # The left and right neighbors will wrap-around, but that's not a
            # problem, since they won't produce false positives.
            var left_neighbor_index := tilemap_index - 1
            var right_neighbor_index := tilemap_index + 1
            var top_neighbor_index := tilemap_index - tilemap_column_count
            var bottom_neighbor_index := tilemap_index + tilemap_column_count
            var top_left_neighbor_index := top_neighbor_index - 1
            var top_right_neighbor_index := top_neighbor_index + 1
            var bottom_left_neighbor_index := bottom_neighbor_index - 1
            var bottom_right_neighbor_index := bottom_neighbor_index + 1
            
            var is_single_vertex_floor_at_index: bool = \
                    tilemap_index_to_floor.has(tilemap_index) and \
                    tilemap_index_to_floor[tilemap_index] \
                        .vertices_array.size() == 1
            var is_single_vertex_ceiling_at_index: bool = \
                    tilemap_index_to_ceiling.has(tilemap_index) and \
                    tilemap_index_to_ceiling[tilemap_index] \
                        .vertices_array.size() == 1
            var is_single_vertex_left_wall_at_index: bool = \
                    tilemap_index_to_left_wall.has(tilemap_index) and \
                    tilemap_index_to_left_wall[tilemap_index] \
                        .vertices_array.size() == 1
            var is_single_vertex_right_wall_at_index: bool = \
                    tilemap_index_to_right_wall.has(tilemap_index) and \
                    tilemap_index_to_right_wall[tilemap_index] \
                        .vertices_array.size() == 1
            
            if is_single_vertex_floor_at_index:
                var floor_surface: _TmpSurface = \
                        tilemap_index_to_floor[tilemap_index]
                var floor_vertex: Vector2 = floor_surface.vertices_array[0]
                
                var top_neighbor: _TmpSurface = \
                        tilemap_index_to_ceiling[top_neighbor_index] if \
                        tilemap_index_to_ceiling.has(
                            top_neighbor_index) else \
                        null
                var top_left_neighbor: _TmpSurface = \
                        tilemap_index_to_ceiling[top_left_neighbor_index] if \
                        tilemap_index_to_ceiling.has(
                            top_left_neighbor_index) else \
                        null
                var top_right_neighbor: _TmpSurface = \
                        tilemap_index_to_ceiling[top_right_neighbor_index] if \
                        tilemap_index_to_ceiling.has(
                            top_right_neighbor_index) else \
                        null
                
                var is_match_with_top_neighbor := \
                        top_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            floor_vertex,
                            top_neighbor.vertices_array.front(),
                            top_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                var is_match_with_top_left_neighbor := \
                        top_left_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            floor_vertex,
                            top_left_neighbor.vertices_array.front(),
                            top_left_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                var is_match_with_top_right_neighbor := \
                        top_right_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            floor_vertex,
                            top_right_neighbor.vertices_array.front(),
                            top_right_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                
                if is_match_with_top_neighbor or \
                        is_match_with_top_left_neighbor or \
                        is_match_with_top_right_neighbor:
                    # We found a match, so remove the single-vertex surface.
                    tilemap_index_to_floor.erase(tilemap_index)
                    floor_surface.free()
                    # Check whether the neighbor is also a single-vertex
                    # surface, which should be removed.
                    if is_match_with_top_neighbor and \
                            top_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_ceiling.erase(top_neighbor_index)
                        top_neighbor.free()
                    if is_match_with_top_left_neighbor and \
                            top_left_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_ceiling.erase(top_left_neighbor_index)
                        top_left_neighbor.free()
                    if is_match_with_top_neighbor and \
                            top_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_ceiling \
                                .erase(top_right_neighbor_index)
                        top_right_neighbor.free()
            
            if is_single_vertex_ceiling_at_index:
                var ceiling_surface: _TmpSurface = \
                        tilemap_index_to_ceiling[tilemap_index]
                var ceiling_vertex: Vector2 = ceiling_surface.vertices_array[0]
                
                var bottom_neighbor: _TmpSurface = \
                        tilemap_index_to_floor[bottom_neighbor_index] if \
                        tilemap_index_to_floor.has(
                            bottom_neighbor_index) else \
                        null
                var bottom_left_neighbor: _TmpSurface = \
                        tilemap_index_to_floor[
                            bottom_left_neighbor_index] if \
                        tilemap_index_to_floor.has(
                            bottom_left_neighbor_index) else \
                        null
                var bottom_right_neighbor: _TmpSurface = \
                        tilemap_index_to_floor[
                            bottom_right_neighbor_index] if \
                        tilemap_index_to_floor.has(
                            bottom_right_neighbor_index) else \
                        null
                
                var is_match_with_bottom_neighbor := \
                        bottom_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            ceiling_vertex,
                            bottom_neighbor.vertices_array.front(),
                            bottom_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                var is_match_with_bottom_left_neighbor := \
                        bottom_left_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            ceiling_vertex,
                            bottom_left_neighbor.vertices_array.front(),
                            bottom_left_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                var is_match_with_bottom_right_neighbor := \
                        bottom_right_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            ceiling_vertex,
                            bottom_right_neighbor.vertices_array.front(),
                            bottom_right_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                
                if is_match_with_bottom_neighbor or \
                        is_match_with_bottom_left_neighbor or \
                        is_match_with_bottom_right_neighbor:
                    # We found a match, so remove the single-vertex surface.
                    tilemap_index_to_ceiling.erase(tilemap_index)
                    ceiling_surface.free()
                    # Check whether the neighbor is also a single-vertex
                    # surface, which should be removed.
                    if is_match_with_bottom_neighbor and \
                            bottom_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_floor.erase(bottom_neighbor_index)
                        bottom_neighbor.free()
                    if is_match_with_bottom_left_neighbor and \
                            bottom_left_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_floor \
                                .erase(bottom_left_neighbor_index)
                        bottom_left_neighbor.free()
                    if is_match_with_bottom_neighbor and \
                            bottom_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_floor \
                                .erase(bottom_right_neighbor_index)
                        bottom_right_neighbor.free()
            
            if is_single_vertex_left_wall_at_index:
                var left_wall_surface: _TmpSurface = \
                        tilemap_index_to_left_wall[tilemap_index]
                var left_wall_vertex: Vector2 = \
                        left_wall_surface.vertices_array[0]
                
                var right_neighbor: _TmpSurface = \
                        tilemap_index_to_right_wall[right_neighbor_index] if \
                        tilemap_index_to_right_wall.has(
                            right_neighbor_index) else \
                        null
                var top_right_neighbor: _TmpSurface = \
                        tilemap_index_to_right_wall[
                            top_right_neighbor_index] if \
                        tilemap_index_to_right_wall.has(
                            top_right_neighbor_index) else \
                        null
                var bottom_right_neighbor: _TmpSurface = \
                        tilemap_index_to_right_wall[
                            bottom_right_neighbor_index] if \
                        tilemap_index_to_right_wall.has(
                            bottom_right_neighbor_index) else \
                        null
                
                var is_match_with_right_neighbor := \
                        right_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            left_wall_vertex,
                            right_neighbor.vertices_array.front(),
                            right_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                var is_match_with_top_right_neighbor := \
                        top_right_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            left_wall_vertex,
                            top_right_neighbor.vertices_array.front(),
                            top_right_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                var is_match_with_bottom_right_neighbor := \
                        bottom_right_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            left_wall_vertex,
                            bottom_right_neighbor.vertices_array.front(),
                            bottom_right_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                
                if is_match_with_right_neighbor or \
                        is_match_with_top_right_neighbor or \
                        is_match_with_bottom_right_neighbor:
                    # We found a match, so remove the single-vertex surface.
                    tilemap_index_to_left_wall.erase(tilemap_index)
                    left_wall_surface.free()
                    # Check whether the neighbor is also a single-vertex
                    # surface, which should be removed.
                    if is_match_with_right_neighbor and \
                            right_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_right_wall.erase(right_neighbor_index)
                        right_neighbor.free()
                    if is_match_with_top_right_neighbor and \
                            top_right_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_right_wall \
                                .erase(top_right_neighbor_index)
                        top_right_neighbor.free()
                    if is_match_with_bottom_right_neighbor and \
                            bottom_right_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_right_wall \
                                .erase(bottom_right_neighbor_index)
                        bottom_right_neighbor.free()
            
            if is_single_vertex_right_wall_at_index:
                var right_wall_surface: _TmpSurface = \
                        tilemap_index_to_right_wall[tilemap_index]
                var right_wall_vertex: Vector2 = \
                        right_wall_surface.vertices_array[0]
                
                var left_neighbor: _TmpSurface = \
                        tilemap_index_to_left_wall[left_neighbor_index] if \
                        tilemap_index_to_left_wall.has(
                            left_neighbor_index) else \
                        null
                var top_left_neighbor: _TmpSurface = \
                        tilemap_index_to_left_wall[
                            top_left_neighbor_index] if \
                        tilemap_index_to_left_wall.has(
                            top_left_neighbor_index) else \
                        null
                var bottom_left_neighbor: _TmpSurface = \
                        tilemap_index_to_left_wall[
                            bottom_left_neighbor_index] if \
                        tilemap_index_to_left_wall.has(
                            bottom_left_neighbor_index) else \
                        null
                
                var is_match_with_left_neighbor := \
                        left_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            right_wall_vertex,
                            left_neighbor.vertices_array.front(),
                            left_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                var is_match_with_top_left_neighbor := \
                        top_left_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            right_wall_vertex,
                            top_left_neighbor.vertices_array.front(),
                            top_left_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                var is_match_with_bottom_left_neighbor := \
                        bottom_left_neighbor != null and \
                        Sc.geometry.do_point_and_segment_intersect(
                            right_wall_vertex,
                            bottom_left_neighbor.vertices_array.front(),
                            bottom_left_neighbor.vertices_array.back(),
                            _EQUAL_POINT_EPSILON)
                
                if is_match_with_left_neighbor or \
                        is_match_with_top_left_neighbor or \
                        is_match_with_bottom_left_neighbor:
                    # We found a match, so remove the single-vertex surface.
                    tilemap_index_to_right_wall.erase(tilemap_index)
                    right_wall_surface.free()
                    # Check whether the neighbor is also a single-vertex
                    # surface, which should be removed.
                    if is_match_with_left_neighbor and \
                            left_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_left_wall.erase(left_neighbor_index)
                        left_neighbor.free()
                    if is_match_with_top_left_neighbor and \
                            top_left_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_left_wall \
                                .erase(top_left_neighbor_index)
                        top_left_neighbor.free()
                    if is_match_with_bottom_left_neighbor and \
                            bottom_left_neighbor.vertices_array.size() == 1:
                        tilemap_index_to_left_wall \
                                .erase(bottom_left_neighbor_index)
                        bottom_left_neighbor.free()


static func _remove_internal_multi_vertex_surfaces(
        tilemap_index_to_floor: Dictionary,
        tilemap_index_to_left_wall: Dictionary,
        tilemap_index_to_right_wall: Dictionary,
        tilemap_index_to_ceiling: Dictionary,
        tile_id_to_coord_to_shape_data: Dictionary,
        tile_map: TileMap) -> void:
    var used_rect := tile_map.get_used_rect()
    var grid_offset := Sc.geometry.snap_vector2_to_integers(used_rect.position)
    var tilemap_row_count: int = used_rect.size.y
    var tilemap_column_count: int = used_rect.size.x
    
    for row in tilemap_row_count:
        for column in tilemap_column_count:
            var tilemap_index: int = row * tilemap_column_count + column
            
            # The left and right neighbors will wrap-around, but that's not a
            # problem, since they won't produce false positives.
            var left_neighbor_index := tilemap_index - 1
            var right_neighbor_index := tilemap_index + 1
            var top_neighbor_index := tilemap_index - tilemap_column_count
            var bottom_neighbor_index := tilemap_index + tilemap_column_count
            
            var current_grid_coord := Vector2(
                    tilemap_index % tilemap_column_count,
                    int(tilemap_index / tilemap_column_count)) + grid_offset
            var left_neighbor_grid_coord := current_grid_coord + Vector2(-1, 0)
            var right_neighbor_grid_coord := current_grid_coord + Vector2(1, 0)
            var top_neighbor_grid_coord := current_grid_coord + Vector2(0, -1)
            var bottom_neighbor_grid_coord := current_grid_coord + Vector2(0, 1)
            
            var current_tile_id := tile_map.get_cellv(current_grid_coord)
            var left_neighbor_tile_id := \
                    tile_map.get_cellv(left_neighbor_grid_coord)
            var right_neighbor_tile_id := \
                    tile_map.get_cellv(right_neighbor_grid_coord)
            var top_neighbor_tile_id := \
                    tile_map.get_cellv(top_neighbor_grid_coord)
            var bottom_neighbor_tile_id := \
                    tile_map.get_cellv(bottom_neighbor_grid_coord)
            var current_tile_coord := tile_map.get_cell_autotile_coord(
                    current_grid_coord.x, current_grid_coord.y)
            var left_neighbor_tile_coord := tile_map.get_cell_autotile_coord(
                    left_neighbor_grid_coord.x, left_neighbor_grid_coord.y)
            var right_neighbor_tile_coord := tile_map.get_cell_autotile_coord(
                    right_neighbor_grid_coord.x, right_neighbor_grid_coord.y)
            var top_neighbor_tile_coord := tile_map.get_cell_autotile_coord(
                    top_neighbor_grid_coord.x, top_neighbor_grid_coord.y)
            var bottom_neighbor_tile_coord := tile_map.get_cell_autotile_coord(
                    bottom_neighbor_grid_coord.x, bottom_neighbor_grid_coord.y)
            
            var current_tile_shape_data: TileShapeData = \
                    tile_id_to_coord_to_shape_data[current_tile_id][
                        current_tile_coord] if \
                    current_tile_id != TileMap.INVALID_CELL else \
                    null
            var left_neighbor_tile_shape_data: TileShapeData = \
                    tile_id_to_coord_to_shape_data[left_neighbor_tile_id][
                        left_neighbor_tile_coord] if \
                    left_neighbor_tile_id != TileMap.INVALID_CELL else \
                    null
            var right_neighbor_tile_shape_data: TileShapeData = \
                    tile_id_to_coord_to_shape_data[right_neighbor_tile_id][
                        right_neighbor_tile_coord] if \
                    right_neighbor_tile_id != TileMap.INVALID_CELL else \
                    null
            var top_neighbor_tile_shape_data: TileShapeData = \
                    tile_id_to_coord_to_shape_data[top_neighbor_tile_id][
                        top_neighbor_tile_coord] if \
                    top_neighbor_tile_id != TileMap.INVALID_CELL else \
                    null
            var bottom_neighbor_tile_shape_data: TileShapeData = \
                    tile_id_to_coord_to_shape_data[bottom_neighbor_tile_id][
                        bottom_neighbor_tile_coord] if \
                    bottom_neighbor_tile_id != TileMap.INVALID_CELL else \
                    null
            
            var is_there_a_non_single_floor_to_ceiling_match: bool = \
                    tilemap_index_to_floor.has(tilemap_index) and \
                    tilemap_index_to_floor[tilemap_index] \
                        .vertices_array.size() > 1 and \
                    tilemap_index_to_ceiling.has(top_neighbor_index) and \
                    tilemap_index_to_ceiling[top_neighbor_index] \
                        .vertices_array.size() > 1 and \
                    is_instance_valid(top_neighbor_tile_shape_data)
            var is_there_a_non_single_ceiling_to_floor_match: bool = \
                    tilemap_index_to_ceiling.has(tilemap_index) and \
                    tilemap_index_to_ceiling[tilemap_index] \
                        .vertices_array.size() > 1 and \
                    tilemap_index_to_floor.has(bottom_neighbor_index) and \
                    tilemap_index_to_floor[bottom_neighbor_index] \
                        .vertices_array.size() > 1 and \
                    is_instance_valid(bottom_neighbor_tile_shape_data)
            var is_there_a_non_single_left_wall_to_right_wall_match: bool = \
                    tilemap_index_to_left_wall.has(tilemap_index) and \
                    tilemap_index_to_left_wall[tilemap_index] \
                        .vertices_array.size() > 1 and \
                    tilemap_index_to_right_wall.has(right_neighbor_index) and \
                    tilemap_index_to_right_wall[right_neighbor_index] \
                        .vertices_array.size() > 1 and \
                    is_instance_valid(right_neighbor_tile_shape_data)
            var is_there_a_non_single_right_wall_to_left_wall_match: bool = \
                    tilemap_index_to_right_wall.has(tilemap_index) and \
                    tilemap_index_to_right_wall[tilemap_index] \
                        .vertices_array.size() > 1 and \
                    tilemap_index_to_left_wall.has(left_neighbor_index) and \
                    tilemap_index_to_left_wall[left_neighbor_index] \
                        .vertices_array.size() > 1 and \
                    is_instance_valid(left_neighbor_tile_shape_data)
            
            if is_there_a_non_single_floor_to_ceiling_match:
                var floor_surface: _TmpSurface = \
                        tilemap_index_to_floor[tilemap_index]
                var ceiling_surface: _TmpSurface = \
                        tilemap_index_to_ceiling[top_neighbor_index]
                var floor_first_point: Vector2 = \
                        floor_surface.vertices_array.front()
                var floor_last_point: Vector2 = \
                        floor_surface.vertices_array.back()
                var ceiling_first_point: Vector2 = \
                        ceiling_surface.vertices_array.front()
                var ceiling_last_point: Vector2 = \
                        ceiling_surface.vertices_array.back()
                
                var do_left_ends_match: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                            floor_first_point,
                            ceiling_last_point,
                            _EQUAL_POINT_EPSILON)
                var do_right_ends_match: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                            floor_last_point,
                            ceiling_first_point,
                            _EQUAL_POINT_EPSILON)
                var is_full_match := do_left_ends_match and do_right_ends_match
                var is_possible_partial_match := \
                        !is_full_match and \
                        current_tile_shape_data \
                            .is_top_along_cell_boundary and \
                        top_neighbor_tile_shape_data \
                            .is_bottom_along_cell_boundary
                
                if is_full_match:
                    # We found a match, so remove both surfaces.
                    tilemap_index_to_floor.erase(tilemap_index)
                    tilemap_index_to_ceiling.erase(top_neighbor_index)
                    floor_surface.free()
                    ceiling_surface.free()
                elif is_possible_partial_match:
                    var is_floor_to_the_left := \
                            floor_first_point.x < \
                            ceiling_last_point.x - _EQUAL_POINT_EPSILON
                    var is_floor_to_the_right := \
                            floor_last_point.x > \
                            ceiling_first_point.x + _EQUAL_POINT_EPSILON
                    if do_left_ends_match:
                        if is_floor_to_the_right:
                            # The floor extends past the ceiling on one side,
                            # so remove the ceiling and truncate the floor.
                            floor_surface.vertices_array[0] = \
                                    ceiling_first_point
                            tilemap_index_to_ceiling.erase(top_neighbor_index)
                            ceiling_surface.free()
                        else:
                            # The ceiling extends past the floor on one side,
                            # so remove the floor and truncate the ceiling.
                            ceiling_surface.vertices_array[1] = \
                                    floor_last_point
                            tilemap_index_to_floor.erase(tilemap_index)
                            floor_surface.free()
                    elif do_right_ends_match:
                        if is_floor_to_the_left:
                            # The floor extends past the ceiling on one side,
                            # so remove the ceiling and truncate the floor.
                            floor_surface.vertices_array[1] = \
                                    ceiling_last_point
                            tilemap_index_to_ceiling.erase(top_neighbor_index)
                            ceiling_surface.free()
                        else:
                            # The ceiling extends past the floor on one side,
                            # so remove the floor and truncate the ceiling.
                            ceiling_surface.vertices_array[0] = \
                                    floor_first_point
                            tilemap_index_to_floor.erase(tilemap_index)
                            floor_surface.free()
                    else:
                        assert(is_floor_to_the_left != is_floor_to_the_right,
                                "Surface parsing currently doesn't support " + \
                                "splitting apart a surface within a given " + \
                                "cell.")
                        # The ceiling extends past the floor on one side, and
                        # the floor extends past the ceiling on the other side,
                        # so truncate both surfaces.
                        if is_floor_to_the_left:
                            floor_surface.vertices_array[1] = \
                                    ceiling_last_point
                            ceiling_surface.vertices_array[1] = \
                                    floor_last_point
                        else: # is_floor_to_the_right
                            floor_surface.vertices_array[0] = \
                                    ceiling_first_point
                            ceiling_surface.vertices_array[0] = \
                                    floor_first_point
            
            if is_there_a_non_single_ceiling_to_floor_match:
                var ceiling_surface: _TmpSurface = \
                        tilemap_index_to_ceiling[tilemap_index]
                var floor_surface: _TmpSurface = \
                        tilemap_index_to_floor[bottom_neighbor_index]
                var ceiling_first_point: Vector2 = \
                        ceiling_surface.vertices_array.front()
                var ceiling_last_point: Vector2 = \
                        ceiling_surface.vertices_array.back()
                var floor_first_point: Vector2 = \
                        floor_surface.vertices_array.front()
                var floor_last_point: Vector2 = \
                        floor_surface.vertices_array.back()
                
                var do_left_ends_match: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                            ceiling_last_point,
                            floor_first_point,
                            _EQUAL_POINT_EPSILON)
                var do_right_ends_match: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                            ceiling_first_point,
                            floor_last_point,
                            _EQUAL_POINT_EPSILON)
                var is_full_match := do_left_ends_match and do_right_ends_match
                var is_possible_partial_match := \
                        !is_full_match and \
                        current_tile_shape_data \
                            .is_bottom_along_cell_boundary and \
                        bottom_neighbor_tile_shape_data \
                            .is_top_along_cell_boundary
                
                if is_full_match:
                    # We found a match, so remove both surfaces.
                    tilemap_index_to_ceiling.erase(tilemap_index)
                    tilemap_index_to_floor.erase(bottom_neighbor_index)
                    ceiling_surface.free()
                    floor_surface.free()
                elif is_possible_partial_match:
                    var is_ceiling_to_the_left := \
                            ceiling_last_point.x < \
                            floor_first_point.x - _EQUAL_POINT_EPSILON
                    var is_ceiling_to_the_right := \
                            ceiling_first_point.x > \
                            floor_last_point.x + _EQUAL_POINT_EPSILON
                    if do_left_ends_match:
                        if is_ceiling_to_the_right:
                            # The ceiling extends past the floor on one side,
                            # so remove the floor and truncate the ceiling.
                            ceiling_surface.vertices_array[1] = \
                                    floor_last_point
                            tilemap_index_to_floor.erase(bottom_neighbor_index)
                            floor_surface.free()
                        else:
                            # The floor extends past the ceiling on one side,
                            # so remove the ceiling and truncate the floor.
                            floor_surface.vertices_array[0] = \
                                    ceiling_first_point
                            tilemap_index_to_ceiling.erase(tilemap_index)
                            ceiling_surface.free()
                    elif do_right_ends_match:
                        if is_ceiling_to_the_left:
                            # The ceiling extends past the floor on one side,
                            # so remove the floor and truncate the ceiling.
                            ceiling_surface.vertices_array[0] = \
                                    floor_first_point
                            tilemap_index_to_floor.erase(bottom_neighbor_index)
                            floor_surface.free()
                        else:
                            # The floor extends past the ceiling on one side,
                            # so remove the ceiling and truncate the floor.
                            floor_surface.vertices_array[1] = \
                                    ceiling_last_point
                            tilemap_index_to_ceiling.erase(tilemap_index)
                            ceiling_surface.free()
                    else:
                        assert(is_ceiling_to_the_left != \
                                    is_ceiling_to_the_right,
                                "Surface parsing currently doesn't support " + \
                                "splitting apart a surface within a given " + \
                                "cell.")
                        # The floor extends past the ceiling on one side, and
                        # the ceiling extends past the floor on the other side,
                        # so truncate both surfaces.
                        if is_ceiling_to_the_left:
                            ceiling_surface.vertices_array[0] = \
                                    floor_first_point
                            floor_surface.vertices_array[0] = \
                                    ceiling_first_point
                        else: # is_ceiling_to_the_right
                            ceiling_surface.vertices_array[1] = \
                                    floor_last_point
                            floor_surface.vertices_array[1] = \
                                    ceiling_last_point
            
            if is_there_a_non_single_left_wall_to_right_wall_match:
                var left_wall_surface: _TmpSurface = \
                        tilemap_index_to_left_wall[tilemap_index]
                var right_wall_surface: _TmpSurface = \
                        tilemap_index_to_right_wall[right_neighbor_index]
                var left_wall_first_point: Vector2 = \
                        left_wall_surface.vertices_array.front()
                var left_wall_last_point: Vector2 = \
                        left_wall_surface.vertices_array.back()
                var right_wall_first_point: Vector2 = \
                        right_wall_surface.vertices_array.front()
                var right_wall_last_point: Vector2 = \
                        right_wall_surface.vertices_array.back()
                
                var do_top_ends_match: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                            left_wall_first_point,
                            right_wall_last_point,
                            _EQUAL_POINT_EPSILON)
                var do_bottom_ends_match: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                            left_wall_last_point,
                            right_wall_first_point,
                            _EQUAL_POINT_EPSILON)
                var is_full_match := do_top_ends_match and do_bottom_ends_match
                var is_possible_partial_match := \
                        !is_full_match and \
                        current_tile_shape_data \
                            .is_right_along_cell_boundary and \
                        right_neighbor_tile_shape_data \
                            .is_left_along_cell_boundary
                
                if is_full_match:
                    # We found a match, so remove both surfaces.
                    tilemap_index_to_left_wall.erase(tilemap_index)
                    tilemap_index_to_right_wall.erase(right_neighbor_index)
                    left_wall_surface.free()
                    right_wall_surface.free()
                elif is_possible_partial_match:
                    var is_left_wall_to_the_top := \
                            left_wall_first_point.x < \
                            right_wall_last_point.x - _EQUAL_POINT_EPSILON
                    var is_left_wall_to_the_bottom := \
                            left_wall_last_point.x > \
                            right_wall_first_point.x + _EQUAL_POINT_EPSILON
                    if do_top_ends_match:
                        if is_left_wall_to_the_bottom:
                            # The left_wall extends past the right_wall on one
                            # side, so remove the right_wall and truncate the
                            # left_wall.
                            left_wall_surface.vertices_array[0] = \
                                    right_wall_first_point
                            tilemap_index_to_right_wall \
                                    .erase(right_neighbor_index)
                            right_wall_surface.free()
                        else:
                            # The right_wall extends past the left_wall on one
                            # side, so remove the left_wall and truncate the
                            # right_wall.
                            right_wall_surface.vertices_array[1] = \
                                    left_wall_last_point
                            tilemap_index_to_left_wall.erase(tilemap_index)
                            left_wall_surface.free()
                    elif do_bottom_ends_match:
                        if is_left_wall_to_the_top:
                            # The left_wall extends past the right_wall on one
                            # side, so remove the right_wall and truncate the
                            # left_wall.
                            left_wall_surface.vertices_array[1] = \
                                    right_wall_last_point
                            tilemap_index_to_right_wall \
                                    .erase(right_neighbor_index)
                            right_wall_surface.free()
                        else:
                            # The right_wall extends past the left_wall on one
                            # side, so remove the left_wall and truncate the
                            # right_wall.
                            right_wall_surface.vertices_array[0] = \
                                    left_wall_first_point
                            tilemap_index_to_left_wall.erase(tilemap_index)
                            left_wall_surface.free()
                    else:
                        assert(is_left_wall_to_the_top != \
                                    is_left_wall_to_the_bottom,
                                "Surface parsing currently doesn't support " + \
                                "splitting apart a surface within a given " + \
                                "cell.")
                        # The right_wall extends past the left_wall on one
                        # side, and the left_wall extends past the right_wall
                        # on the other side, so truncate both surfaces.
                        if is_left_wall_to_the_top:
                            left_wall_surface.vertices_array[1] = \
                                    right_wall_last_point
                            right_wall_surface.vertices_array[1] = \
                                    left_wall_last_point
                        else: # is_left_wall_to_the_bottom
                            left_wall_surface.vertices_array[0] = \
                                    right_wall_first_point
                            right_wall_surface.vertices_array[0] = \
                                    left_wall_first_point
            
            if is_there_a_non_single_right_wall_to_left_wall_match:
                var right_wall_surface: _TmpSurface = \
                        tilemap_index_to_right_wall[tilemap_index]
                var left_wall_surface: _TmpSurface = \
                        tilemap_index_to_left_wall[left_neighbor_index]
                var right_wall_first_point: Vector2 = \
                        right_wall_surface.vertices_array.front()
                var right_wall_last_point: Vector2 = \
                        right_wall_surface.vertices_array.back()
                var left_wall_first_point: Vector2 = \
                        left_wall_surface.vertices_array.front()
                var left_wall_last_point: Vector2 = \
                        left_wall_surface.vertices_array.back()
                
                var do_top_ends_match: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                            right_wall_last_point,
                            left_wall_first_point,
                            _EQUAL_POINT_EPSILON)
                var do_bottom_ends_match: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                            right_wall_first_point,
                            left_wall_last_point,
                            _EQUAL_POINT_EPSILON)
                var is_full_match := do_top_ends_match and do_bottom_ends_match
                var is_possible_partial_match := \
                        !is_full_match and \
                        current_tile_shape_data \
                            .is_left_along_cell_boundary and \
                        left_neighbor_tile_shape_data \
                            .is_right_along_cell_boundary
                
                if is_full_match:
                    # We found a match, so remove both surfaces.
                    tilemap_index_to_right_wall.erase(tilemap_index)
                    tilemap_index_to_left_wall.erase(left_neighbor_index)
                    right_wall_surface.free()
                    left_wall_surface.free()
                elif is_possible_partial_match:
                    var is_right_wall_to_the_top := \
                            right_wall_last_point.x < \
                            left_wall_first_point.x - _EQUAL_POINT_EPSILON
                    var is_right_wall_to_the_bottom := \
                            right_wall_first_point.x > \
                            left_wall_last_point.x + _EQUAL_POINT_EPSILON
                    if do_top_ends_match:
                        if is_right_wall_to_the_bottom:
                            # The right_wall extends past the left_wall on one
                            # side, so remove the left_wall and truncate the
                            # right_wall.
                            right_wall_surface.vertices_array[1] = \
                                    left_wall_last_point
                            tilemap_index_to_left_wall \
                                    .erase(left_neighbor_index)
                            left_wall_surface.free()
                        else:
                            # The left_wall extends past the right_wall on one
                            # side, so remove the right_wall and truncate the
                            # left_wall.
                            left_wall_surface.vertices_array[0] = \
                                    right_wall_first_point
                            tilemap_index_to_right_wall.erase(tilemap_index)
                            right_wall_surface.free()
                    elif do_bottom_ends_match:
                        if is_right_wall_to_the_top:
                            # The right_wall extends past the left_wall on one
                            # side, so remove the left_wall and truncate the
                            # right_wall.
                            right_wall_surface.vertices_array[0] = \
                                    left_wall_first_point
                            tilemap_index_to_left_wall \
                                    .erase(left_neighbor_index)
                            left_wall_surface.free()
                        else:
                            # The left_wall extends past the right_wall on one
                            # side, so remove the right_wall and truncate the
                            # left_wall.
                            left_wall_surface.vertices_array[1] = \
                                    right_wall_last_point
                            tilemap_index_to_right_wall.erase(tilemap_index)
                            right_wall_surface.free()
                    else:
                        assert(is_right_wall_to_the_top != \
                                    is_right_wall_to_the_bottom,
                                "Surface parsing currently doesn't support " + \
                                "splitting apart a surface within a given " + \
                                "cell.")
                        # The left_wall extends past the right_wall on one
                        # side, and the right_wall extends past the left_wall
                        # on the other side, so truncate both surfaces.
                        if is_right_wall_to_the_top:
                            right_wall_surface.vertices_array[0] = \
                                    left_wall_first_point
                            left_wall_surface.vertices_array[0] = \
                                    right_wall_first_point
                        else: # is_right_wall_to_the_bottom
                            right_wall_surface.vertices_array[1] = \
                                    left_wall_last_point
                            left_wall_surface.vertices_array[1] = \
                                    right_wall_last_point


static func _replace_surface(
        old_surface: _TmpSurface,
        new_surface: _TmpSurface,
        collection: Dictionary) -> void:
    for index in old_surface.tilemap_indices:
        collection[index] = new_surface
    old_surface.free()


# Merges adjacent continuous surfaces.
static func _merge_continuous_surfaces(
        tilemap_index_to_floor: Dictionary,
        tilemap_index_to_left_wall: Dictionary,
        tilemap_index_to_right_wall: Dictionary,
        tilemap_index_to_ceiling: Dictionary,
        tile_map: TileMap) -> void:
    var used_rect := tile_map.get_used_rect()
    var tilemap_row_count: int = used_rect.size.y
    var tilemap_column_count: int = used_rect.size.x
    
    for row in tilemap_row_count:
        for column in tilemap_column_count:
            var tilemap_index: int = row * tilemap_column_count + column
            
            # The left and right neighbors can wrap-around, but that's not a
            # problem, since they won't produce false positives.
            var right_neighbor_index := tilemap_index + 1
            var bottom_neighbor_index := tilemap_index + tilemap_column_count
            var bottom_left_neighbor_index := bottom_neighbor_index - 1
            var bottom_right_neighbor_index := bottom_neighbor_index + 1
            
            if tilemap_index_to_floor.has(tilemap_index) and \
                    tilemap_index_to_floor.has(right_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_floor[tilemap_index]
                var right_surface: _TmpSurface = \
                        tilemap_index_to_floor[right_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        current_surface.vertices_array.back(),
                        right_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            right_surface.properties:
                        current_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                current_surface.vertices_array,
                                right_surface.vertices_array)
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                right_surface.tilemap_indices)
                        tilemap_index_to_floor[right_neighbor_index] = \
                                current_surface
                        _replace_surface(
                                right_surface,
                                current_surface,
                                tilemap_index_to_floor)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_floor.erase(tilemap_index)
                            current_surface.free()
                        if right_surface.vertices_array.size() == 1:
                            tilemap_index_to_floor.erase(right_neighbor_index)
                            right_surface.free()
            
            if tilemap_index_to_floor.has(tilemap_index) and \
                    tilemap_index_to_floor.has(bottom_left_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_floor[tilemap_index]
                var bottom_left_surface: _TmpSurface = \
                        tilemap_index_to_floor[bottom_left_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        bottom_left_surface.vertices_array.back(),
                        current_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            bottom_left_surface.properties:
                        bottom_left_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                bottom_left_surface.vertices_array,
                                current_surface.vertices_array)
                        current_surface.vertices_array = \
                                bottom_left_surface.vertices_array
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                bottom_left_surface.tilemap_indices)
                        tilemap_index_to_floor[bottom_left_neighbor_index] = \
                                current_surface
                        _replace_surface(
                                bottom_left_surface,
                                current_surface,
                                tilemap_index_to_floor)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_floor.erase(tilemap_index)
                            current_surface.free()
                        if bottom_left_surface.vertices_array.size() == 1:
                            tilemap_index_to_floor.erase(
                                    bottom_left_neighbor_index)
                            bottom_left_surface.free()
            
            if tilemap_index_to_floor.has(tilemap_index) and \
                    tilemap_index_to_floor.has(bottom_right_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_floor[tilemap_index]
                var bottom_right_surface: _TmpSurface = \
                        tilemap_index_to_floor[bottom_right_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        current_surface.vertices_array.back(),
                        bottom_right_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            bottom_right_surface.properties:
                        current_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                current_surface.vertices_array,
                                bottom_right_surface.vertices_array)
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                bottom_right_surface.tilemap_indices)
                        tilemap_index_to_floor[bottom_right_neighbor_index] = \
                                current_surface
                        _replace_surface(
                                bottom_right_surface,
                                current_surface,
                                tilemap_index_to_floor)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_floor.erase(tilemap_index)
                            current_surface.free()
                        if bottom_right_surface.vertices_array.size() == 1:
                            tilemap_index_to_floor.erase(
                                    bottom_right_neighbor_index)
                            bottom_right_surface.free()
            
            if tilemap_index_to_ceiling.has(tilemap_index) and \
                    tilemap_index_to_ceiling.has(right_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_ceiling[tilemap_index]
                var right_surface: _TmpSurface = \
                        tilemap_index_to_ceiling[right_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        right_surface.vertices_array.back(),
                        current_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            right_surface.properties:
                        right_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                right_surface.vertices_array,
                                current_surface.vertices_array)
                        current_surface.vertices_array = \
                                right_surface.vertices_array
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                right_surface.tilemap_indices)
                        tilemap_index_to_ceiling[right_neighbor_index] = \
                                current_surface
                        _replace_surface(
                                right_surface,
                                current_surface,
                                tilemap_index_to_ceiling)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_ceiling.erase(tilemap_index)
                            current_surface.free()
                        if right_surface.vertices_array.size() == 1:
                            tilemap_index_to_ceiling.erase(
                                    right_neighbor_index)
                            right_surface.free()
            
            if tilemap_index_to_ceiling.has(tilemap_index) and \
                    tilemap_index_to_ceiling.has(bottom_left_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_ceiling[tilemap_index]
                var bottom_left_surface: _TmpSurface = \
                        tilemap_index_to_ceiling[bottom_left_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        current_surface.vertices_array.back(),
                        bottom_left_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            bottom_left_surface.properties:
                        current_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                current_surface.vertices_array,
                                bottom_left_surface.vertices_array)
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                bottom_left_surface.tilemap_indices)
                        tilemap_index_to_ceiling[
                                bottom_left_neighbor_index] = current_surface
                        _replace_surface(
                                bottom_left_surface,
                                current_surface,
                                tilemap_index_to_ceiling)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_ceiling.erase(tilemap_index)
                            current_surface.free()
                        if bottom_left_surface.vertices_array.size() == 1:
                            tilemap_index_to_ceiling.erase(
                                    bottom_left_neighbor_index)
                            bottom_left_surface.free()
            
            if tilemap_index_to_ceiling.has(tilemap_index) and \
                    tilemap_index_to_ceiling.has(bottom_right_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_ceiling[tilemap_index]
                var bottom_right_surface: _TmpSurface = \
                        tilemap_index_to_ceiling[bottom_right_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        bottom_right_surface.vertices_array.back(),
                        current_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            bottom_right_surface.properties:
                        bottom_right_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                bottom_right_surface.vertices_array,
                                current_surface.vertices_array)
                        current_surface.vertices_array = \
                                bottom_right_surface.vertices_array
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                bottom_right_surface.tilemap_indices)
                        tilemap_index_to_ceiling[
                                bottom_right_neighbor_index] = current_surface
                        _replace_surface(
                                bottom_right_surface,
                                current_surface,
                                tilemap_index_to_ceiling)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_ceiling.erase(tilemap_index)
                            current_surface.free()
                        if bottom_right_surface.vertices_array.size() == 1:
                            tilemap_index_to_ceiling.erase(
                                    bottom_right_neighbor_index)
                            bottom_right_surface.free()
            
            if tilemap_index_to_left_wall.has(tilemap_index) and \
                    tilemap_index_to_left_wall.has(bottom_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_left_wall[tilemap_index]
                var bottom_surface: _TmpSurface = \
                        tilemap_index_to_left_wall[bottom_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        current_surface.vertices_array.back(),
                        bottom_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            bottom_surface.properties:
                        current_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                current_surface.vertices_array,
                                bottom_surface.vertices_array)
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                bottom_surface.tilemap_indices)
                        tilemap_index_to_left_wall[bottom_neighbor_index] = \
                                current_surface
                        _replace_surface(
                                bottom_surface,
                                current_surface,
                                tilemap_index_to_left_wall)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_left_wall.erase(tilemap_index)
                            current_surface.free()
                        if bottom_surface.vertices_array.size() == 1:
                            tilemap_index_to_left_wall.erase(
                                    bottom_neighbor_index)
                            bottom_surface.free()
            
            if tilemap_index_to_left_wall.has(tilemap_index) and \
                    tilemap_index_to_left_wall.has(bottom_left_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_left_wall[tilemap_index]
                var bottom_left_surface: _TmpSurface = \
                        tilemap_index_to_left_wall[bottom_left_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        current_surface.vertices_array.back(),
                        bottom_left_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            bottom_left_surface.properties:
                        current_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                current_surface.vertices_array,
                                bottom_left_surface.vertices_array)
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                bottom_left_surface.tilemap_indices)
                        tilemap_index_to_left_wall[
                                bottom_left_neighbor_index] = current_surface
                        _replace_surface(
                                bottom_left_surface,
                                current_surface,
                                tilemap_index_to_left_wall)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_left_wall.erase(tilemap_index)
                            current_surface.free()
                        if bottom_left_surface.vertices_array.size() == 1:
                            tilemap_index_to_left_wall.erase(
                                    bottom_left_neighbor_index)
                            bottom_left_surface.free()
            
            if tilemap_index_to_left_wall.has(tilemap_index) and \
                    tilemap_index_to_left_wall \
                        .has(bottom_right_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_left_wall[tilemap_index]
                var bottom_right_surface: _TmpSurface = \
                        tilemap_index_to_left_wall[
                            bottom_right_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        current_surface.vertices_array.back(),
                        bottom_right_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            bottom_right_surface.properties:
                        current_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                current_surface.vertices_array,
                                bottom_right_surface.vertices_array)
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                bottom_right_surface.tilemap_indices)
                        tilemap_index_to_left_wall[
                                bottom_right_neighbor_index] = current_surface
                        _replace_surface(
                                bottom_right_surface,
                                current_surface,
                                tilemap_index_to_left_wall)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_left_wall.erase(tilemap_index)
                            current_surface.free()
                        if bottom_right_surface.vertices_array.size() == 1:
                            tilemap_index_to_left_wall.erase(
                                    bottom_right_neighbor_index)
                            bottom_right_surface.free()
            
            if tilemap_index_to_right_wall.has(tilemap_index) and \
                    tilemap_index_to_right_wall.has(bottom_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_right_wall[tilemap_index]
                var bottom_surface: _TmpSurface = \
                        tilemap_index_to_right_wall[bottom_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        bottom_surface.vertices_array.back(),
                        current_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            bottom_surface.properties:
                        bottom_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                bottom_surface.vertices_array,
                                current_surface.vertices_array)
                        current_surface.vertices_array = \
                                bottom_surface.vertices_array
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                bottom_surface.tilemap_indices)
                        tilemap_index_to_right_wall[bottom_neighbor_index] = \
                                current_surface
                        _replace_surface(
                                bottom_surface,
                                current_surface,
                                tilemap_index_to_right_wall)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_right_wall.erase(tilemap_index)
                            current_surface.free()
                        if bottom_surface.vertices_array.size() == 1:
                            tilemap_index_to_right_wall.erase(
                                    bottom_neighbor_index)
                            bottom_surface.free()
            
            if tilemap_index_to_right_wall.has(tilemap_index) and \
                    tilemap_index_to_right_wall \
                        .has(bottom_left_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_right_wall[tilemap_index]
                var bottom_left_surface: _TmpSurface = \
                        tilemap_index_to_right_wall[
                            bottom_left_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        bottom_left_surface.vertices_array.back(),
                        current_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            bottom_left_surface.properties:
                        bottom_left_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                bottom_left_surface.vertices_array,
                                current_surface.vertices_array)
                        current_surface.vertices_array = \
                                bottom_left_surface.vertices_array
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                bottom_left_surface.tilemap_indices)
                        tilemap_index_to_right_wall[
                                bottom_left_neighbor_index] = current_surface
                        _replace_surface(
                                bottom_left_surface,
                                current_surface,
                                tilemap_index_to_right_wall)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_right_wall.erase(tilemap_index)
                            current_surface.free()
                        if bottom_left_surface.vertices_array.size() == 1:
                            tilemap_index_to_right_wall.erase(
                                    bottom_left_neighbor_index)
                            bottom_left_surface.free()
            
            if tilemap_index_to_right_wall.has(tilemap_index) and \
                    tilemap_index_to_right_wall \
                        .has(bottom_right_neighbor_index):
                var current_surface: _TmpSurface = \
                        tilemap_index_to_right_wall[tilemap_index]
                var bottom_right_surface: _TmpSurface = \
                        tilemap_index_to_right_wall[
                            bottom_right_neighbor_index]
                if Sc.geometry.are_points_equal_with_epsilon(
                        bottom_right_surface.vertices_array.back(),
                        current_surface.vertices_array.front(),
                        _EQUAL_POINT_EPSILON):
                    if current_surface.properties == \
                            bottom_right_surface.properties:
                        bottom_right_surface.vertices_array.pop_back()
                        Sc.utils.concat(
                                bottom_right_surface.vertices_array,
                                current_surface.vertices_array)
                        current_surface.vertices_array = \
                                bottom_right_surface.vertices_array
                        Sc.utils.concat(
                                current_surface.tilemap_indices,
                                bottom_right_surface.tilemap_indices)
                        tilemap_index_to_right_wall[
                                bottom_right_neighbor_index] = current_surface
                        _replace_surface(
                                bottom_right_surface,
                                current_surface,
                                tilemap_index_to_right_wall)
                    else:
                        if current_surface.vertices_array.size() == 1:
                            tilemap_index_to_right_wall.erase(tilemap_index)
                            current_surface.free()
                        if bottom_right_surface.vertices_array.size() == 1:
                            tilemap_index_to_right_wall.erase(
                                    bottom_right_neighbor_index)
                            bottom_right_surface.free()


static func _get_surface_list_from_map(
        tilemap_index_to_surface: Dictionary) -> Array:
    var surface_set := {}
    for surface in tilemap_index_to_surface.values():
        surface_set[surface] = true
    return surface_set.keys()


static func _remove_internal_collinear_vertices(surfaces: Array) -> void:
    for surface in surfaces:
        var vertices: Array = surface.vertices_array
        var i := 0
        var count := vertices.size()
        while i + 2 < count:
            if Sc.geometry.are_points_collinear(
                    vertices[i],
                    vertices[i + 1],
                    vertices[i + 2]):
                vertices.remove(i + 1)
                i -= 1
                count -= 1
            i += 1


static func _assign_neighbor_surfaces(
        floors: Array,
        ceilings: Array,
        left_walls: Array,
        right_walls: Array) -> void:
    var surface1_end1 := Vector2.INF
    var surface1_end2 := Vector2.INF
    var surface2_end := Vector2.INF
    var diff_x: float
    var diff_y: float
    
    for floor_surface in floors:
        # The left edge of the floor.
        surface1_end1 = floor_surface.first_point
        # The right edge of the floor.
        surface1_end2 = floor_surface.last_point
        
        for right_wall in right_walls:
            # Check for a convex neighbor at the top edge of the right wall.
            surface2_end = right_wall.last_point
            diff_x = surface1_end1.x - surface2_end.x
            diff_y = surface1_end1.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                floor_surface.counter_clockwise_convex_neighbor = right_wall
                right_wall.clockwise_convex_neighbor = floor_surface
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if floor_surface.clockwise_neighbor != null:
                    break
            
            # Check for a concave neighbor at the bottom edge of the right
            # wall.
            surface2_end = right_wall.first_point
            diff_x = surface1_end2.x - surface2_end.x
            diff_y = surface1_end2.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                floor_surface.clockwise_concave_neighbor = right_wall
                right_wall.counter_clockwise_concave_neighbor = floor_surface
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if floor_surface.counter_clockwise_neighbor != null:
                    break
        
        for left_wall in left_walls:
            # Check for a convex neighbor at the top edge of the left wall.
            surface2_end = left_wall.first_point
            diff_x = surface1_end2.x - surface2_end.x
            diff_y = surface1_end2.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                floor_surface.clockwise_convex_neighbor = left_wall
                left_wall.counter_clockwise_convex_neighbor = floor_surface
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if floor_surface.counter_clockwise_neighbor != null:
                    break
            
            # Check for a concave neighbor at the bottom edge of the left wall.
            surface2_end = left_wall.last_point
            diff_x = surface1_end1.x - surface2_end.x
            diff_y = surface1_end1.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                floor_surface.counter_clockwise_concave_neighbor = left_wall
                left_wall.clockwise_concave_neighbor = floor_surface
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if floor_surface.clockwise_neighbor != null:
                    break
    
    for ceiling in ceilings:
        # The right edge of the ceiling.
        surface1_end1 = ceiling.first_point
        # The left edge of the ceiling.
        surface1_end2 = ceiling.last_point
        
        for left_wall in left_walls:
            # Check for a convex neighbor at the bottom edge of the left wall.
            surface2_end = left_wall.last_point
            diff_x = surface1_end1.x - surface2_end.x
            diff_y = surface1_end1.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                ceiling.counter_clockwise_convex_neighbor = left_wall
                left_wall.clockwise_convex_neighbor = ceiling
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if ceiling.clockwise_neighbor != null:
                    break
            
            # Check for a concave neighbor at the top edge of the left wall.
            surface2_end = left_wall.first_point
            diff_x = surface1_end2.x - surface2_end.x
            diff_y = surface1_end2.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                ceiling.clockwise_concave_neighbor = left_wall
                left_wall.counter_clockwise_concave_neighbor = ceiling
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if ceiling.counter_clockwise_neighbor != null:
                    break
        
        for right_wall in right_walls:
            # Check for a convex neighbor at the bottom edge of the right wall.
            surface2_end = right_wall.first_point
            diff_x = surface1_end2.x - surface2_end.x
            diff_y = surface1_end2.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                ceiling.clockwise_convex_neighbor = right_wall
                right_wall.counter_clockwise_convex_neighbor = ceiling
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if ceiling.counter_clockwise_neighbor != null:
                    break
            
            # Check for a concave neighbor at the top edge of the right wall.
            surface2_end = right_wall.last_point
            diff_x = surface1_end1.x - surface2_end.x
            diff_y = surface1_end1.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                ceiling.counter_clockwise_concave_neighbor = right_wall
                right_wall.clockwise_concave_neighbor = ceiling
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if ceiling.clockwise_neighbor != null:
                    break
    
    # Check for collinear neighbors.
    for floor_surface in floors:
        if floor_surface.counter_clockwise_neighbor != null and \
                floor_surface.clockwise_neighbor != null:
            continue
        
        # The left edge of the floor.
        surface1_end1 = floor_surface.first_point
        # The right edge of the floor.
        surface1_end2 = floor_surface.last_point
        
        for other_floor in floors:
            if floor_surface == other_floor:
                continue
            
            # Check for a collinear neighbor on the right side.
            surface2_end = other_floor.first_point
            diff_x = surface1_end2.x - surface2_end.x
            diff_y = surface1_end2.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                floor_surface.clockwise_collinear_neighbor = other_floor
                other_floor.counter_clockwise_collinear_neighbor = floor_surface
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if floor_surface.counter_clockwise_neighbor != null:
                    break
            
            # Check for a collinear neighbor on the left side.
            surface2_end = other_floor.last_point
            diff_x = surface1_end1.x - surface2_end.x
            diff_y = surface1_end1.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                floor_surface.counter_clockwise_collinear_neighbor = other_floor
                other_floor.clockwise_collinear_neighbor = floor_surface
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if floor_surface.clockwise_neighbor != null:
                    break
    
    # Check for collinear neighbors.
    for ceiling in ceilings:
        if ceiling.counter_clockwise_neighbor != null and \
                ceiling.clockwise_neighbor != null:
            continue
        
        # The right edge of the ceiling.
        surface1_end1 = ceiling.first_point
        # The left edge of the ceiling.
        surface1_end2 = ceiling.last_point
        
        for other_ceiling in ceilings:
            if ceiling == other_ceiling:
                continue
            
            # Check for a collinear neighbor on the left side.
            surface2_end = other_ceiling.first_point
            diff_x = surface1_end2.x - surface2_end.x
            diff_y = surface1_end2.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                ceiling.clockwise_collinear_neighbor = other_ceiling
                other_ceiling.counter_clockwise_collinear_neighbor = ceiling
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if ceiling.counter_clockwise_neighbor != null:
                    break
            
            # Check for a collinear neighbor on the right side.
            surface2_end = other_ceiling.last_point
            diff_x = surface1_end1.x - surface2_end.x
            diff_y = surface1_end1.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                ceiling.counter_clockwise_collinear_neighbor = other_ceiling
                other_ceiling.clockwise_collinear_neighbor = ceiling
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if ceiling.clockwise_neighbor != null:
                    break
    
    # Check for collinear neighbors.
    for left_wall in left_walls:
        if left_wall.counter_clockwise_neighbor != null and \
                left_wall.clockwise_neighbor != null:
            continue
        
        # The left edge of the wall.
        surface1_end1 = left_wall.first_point
        # The right edge of the wall.
        surface1_end2 = left_wall.last_point
        
        for other_wall in left_walls:
            if left_wall == other_wall:
                continue
            
            # Check for a collinear neighbor on the bottom side.
            surface2_end = other_wall.first_point
            diff_x = surface1_end2.x - surface2_end.x
            diff_y = surface1_end2.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                left_wall.clockwise_collinear_neighbor = other_wall
                other_wall.counter_clockwise_collinear_neighbor = left_wall
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if left_wall.counter_clockwise_neighbor != null:
                    break
            
            # Check for a collinear neighbor on the top side.
            surface2_end = other_wall.last_point
            diff_x = surface1_end1.x - surface2_end.x
            diff_y = surface1_end1.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                left_wall.counter_clockwise_collinear_neighbor = other_wall
                other_wall.clockwise_collinear_neighbor = left_wall
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if left_wall.clockwise_neighbor != null:
                    break
    
    # Check for collinear neighbors.
    for right_wall in right_walls:
        if right_wall.counter_clockwise_neighbor != null and \
                right_wall.clockwise_neighbor != null:
            continue
        
        # The left edge of the wall.
        surface1_end1 = right_wall.first_point
        # The right edge of the wall.
        surface1_end2 = right_wall.last_point
        
        for other_wall in right_walls:
            if right_wall == other_wall:
                continue
            
            # Check for a collinear neighbor on the top side.
            surface2_end = other_wall.first_point
            diff_x = surface1_end2.x - surface2_end.x
            diff_y = surface1_end2.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                right_wall.clockwise_collinear_neighbor = other_wall
                other_wall.counter_clockwise_collinear_neighbor = right_wall
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if right_wall.counter_clockwise_neighbor != null:
                    break
            
            # Check for a collinear neighbor on the bottom side.
            surface2_end = other_wall.last_point
            diff_x = surface1_end1.x - surface2_end.x
            diff_y = surface1_end1.y - surface2_end.y
            if diff_x < _EQUAL_POINT_EPSILON and \
                    diff_x > -_EQUAL_POINT_EPSILON and \
                    diff_y < _EQUAL_POINT_EPSILON and \
                    diff_y > -_EQUAL_POINT_EPSILON:
                right_wall.counter_clockwise_collinear_neighbor = other_wall
                other_wall.clockwise_collinear_neighbor = right_wall
                # There can only be one clockwise and one counter-clockwise
                # neighbor.
                if right_wall.clockwise_neighbor != null:
                    break
    
    # -   It is possible for a floor to be adjacent to a ceiling.
    # -   So check for any corresponding unassigned neighbor references.
    for floor_surface in floors:
        # There can only be one clockwise and one counter-clockwise neighbor.
        if floor_surface.counter_clockwise_neighbor == null:
            # The left edge of the floor.
            surface1_end1 = floor_surface.first_point
            for ceiling in ceilings:
                # Check for a concave neighbor at the left edge of the ceiling.
                surface2_end = ceiling.last_point
                diff_x = surface1_end1.x - surface2_end.x
                diff_y = surface1_end1.y - surface2_end.y
                if diff_x < _EQUAL_POINT_EPSILON and \
                        diff_x > -_EQUAL_POINT_EPSILON and \
                        diff_y < _EQUAL_POINT_EPSILON and \
                        diff_y > -_EQUAL_POINT_EPSILON:
                    floor_surface.counter_clockwise_concave_neighbor = ceiling
                    ceiling.clockwise_concave_neighbor = floor_surface
        
        # There can only be one clockwise and one counter-clockwise neighbor.
        if floor_surface.clockwise_neighbor == null:
            # The right edge of the floor.
            surface1_end2 = floor_surface.last_point
            for ceiling in ceilings:
                # Check for a concave neighbor at the left edge of the ceiling.
                surface2_end = ceiling.first_point
                diff_x = surface1_end2.x - surface2_end.x
                diff_y = surface1_end2.y - surface2_end.y
                if diff_x < _EQUAL_POINT_EPSILON and \
                        diff_x > -_EQUAL_POINT_EPSILON and \
                        diff_y < _EQUAL_POINT_EPSILON and \
                        diff_y > -_EQUAL_POINT_EPSILON:
                    floor_surface.clockwise_concave_neighbor = ceiling
                    ceiling.counter_clockwise_concave_neighbor = floor_surface
    
    # -   It is possible for a left-wall to be adjacent to a right-wall.
    # -   So check for any corresponding unassigned neighbor references.
    for right_wall in right_walls:
        # There can only be one clockwise and one counter-clockwise neighbor.
        if right_wall.counter_clockwise_neighbor == null:
            # The bottom edge of the right_wall.
            surface1_end1 = right_wall.first_point
            for left_wall in left_walls:
                # Check for a concave neighbor at the bottom edge of the
                # left_wall.
                surface2_end = left_wall.last_point
                diff_x = surface1_end1.x - surface2_end.x
                diff_y = surface1_end1.y - surface2_end.y
                if diff_x < _EQUAL_POINT_EPSILON and \
                        diff_x > -_EQUAL_POINT_EPSILON and \
                        diff_y < _EQUAL_POINT_EPSILON and \
                        diff_y > -_EQUAL_POINT_EPSILON:
                    right_wall.counter_clockwise_concave_neighbor = left_wall
                    left_wall.clockwise_concave_neighbor = right_wall
        
        # There can only be one clockwise and one counter-clockwise neighbor.
        if right_wall.clockwise_neighbor == null:
            # The top edge of the right_wall.
            surface1_end2 = right_wall.last_point
            for left_wall in left_walls:
                # Check for a concave neighbor at the top edge of the left_wall.
                surface2_end = left_wall.first_point
                diff_x = surface1_end2.x - surface2_end.x
                diff_y = surface1_end2.y - surface2_end.y
                if diff_x < _EQUAL_POINT_EPSILON and \
                        diff_x > -_EQUAL_POINT_EPSILON and \
                        diff_y < _EQUAL_POINT_EPSILON and \
                        diff_y > -_EQUAL_POINT_EPSILON:
                    right_wall.clockwise_concave_neighbor = left_wall
                    left_wall.counter_clockwise_concave_neighbor = right_wall


static func _calculate_shape_bounding_boxes_for_surfaces(
        surfaces: Array) -> void:
    for surface in surfaces:
        # Calculate the combined bounding box for the overall collection of
        # transitively connected surfaces.
        var connected_region_bounding_box: Rect2 = surface.bounding_box
        var connected_surface: Surface = surface.clockwise_neighbor
        while connected_surface != surface:
            connected_region_bounding_box = \
                    connected_region_bounding_box.merge(
                            connected_surface.bounding_box)
            connected_surface = connected_surface.clockwise_neighbor
        
        # Record the combined bounding box on each surface.
        surface.connected_region_bounding_box = connected_region_bounding_box
        connected_surface = surface.clockwise_neighbor
        while connected_surface != surface:
            connected_surface.connected_region_bounding_box = \
                    connected_region_bounding_box
            connected_surface = connected_surface.clockwise_neighbor


static func _assert_surfaces_have_neighbors(surfaces: Array) -> void:
    for surface in surfaces:
        assert(surface.clockwise_neighbor != null)
        assert(surface.counter_clockwise_neighbor != null)


static func _populate_surface_objects(
        tmp_surfaces: Array,
        side: int) -> void:
    for tmp_surface in tmp_surfaces:
        tmp_surface.surface = Surface.new(
                tmp_surface.vertices_array,
                side,
                tmp_surface.tile_map,
                tmp_surface.tilemap_indices,
                tmp_surface.properties)


static func _copy_surfaces_to_main_collection(
        tmp_surfaces: Array,
        main_collection: Array) -> void:
    for tmp_surface in tmp_surfaces:
        main_collection.push_back(tmp_surface.surface)


static func _create_tilemap_mapping_from_surfaces(
        surfaces: Array) -> Dictionary:
    var result = {}
    for surface in surfaces:
        for tilemap_index in surface.tilemap_indices:
            result[tilemap_index] = surface
    return result


static func _free_objects(objects: Array) -> void:
    for object in objects:
        object.free()


class _TmpSurface extends Object:
    # Array<Vector2>
    var vertices_array: Array
    var tile_map: SurfacesTilemap
    # Array<int>
    var tilemap_indices: Array
    var properties: SurfaceProperties
    var surface: Surface


func _parse_surface_mark(
        surface_store: SurfaceStore,
        surface_mark: SurfaceMark,
        tile_map: TileMap) -> void:
    var mark_cell_size := surface_mark.cell_size
    var tilemap_cell_size := mark_cell_size * 2.0
    
    for mark_position in surface_mark.get_used_cells():
        var mark_position_x := int(mark_position.x)
        var mark_position_y := int(mark_position.y)
        var tilemap_position_x := int(floor((mark_position_x - 1) / 2.0))
        var tilemap_position_y := int(floor((mark_position_y - 1) / 2.0))
        var is_between_tilemap_cells_horizontally := \
                mark_position_x % 2 == 0
        var is_between_tilemap_cells_vertically := \
                mark_position_y % 2 == 0
        
        var tilemap_positions: Array
        if is_between_tilemap_cells_horizontally and \
                is_between_tilemap_cells_vertically:
            tilemap_positions = [
                Vector2(tilemap_position_x, tilemap_position_y),
                Vector2(tilemap_position_x + 1, tilemap_position_y),
                Vector2(tilemap_position_x, tilemap_position_y + 1),
                Vector2(tilemap_position_x + 1, tilemap_position_y + 1),
            ]
        elif is_between_tilemap_cells_horizontally:
            tilemap_positions = [
                Vector2(tilemap_position_x, tilemap_position_y),
                Vector2(tilemap_position_x + 1, tilemap_position_y),
            ]
        elif is_between_tilemap_cells_vertically:
            tilemap_positions = [
                Vector2(tilemap_position_x, tilemap_position_y),
                Vector2(tilemap_position_x, tilemap_position_y + 1),
            ]
        else:
            tilemap_positions = [
                Vector2(tilemap_position_x, tilemap_position_y),
            ]
        
        var mark_cell_min_world_coords: Vector2 = \
                mark_position * mark_cell_size
        var mark_cell_max_world_coords := \
                mark_cell_min_world_coords + mark_cell_size
        for tilemap_position in tilemap_positions:
            var tilemap_index := \
                    Sc.geometry.get_tilemap_index_from_grid_coord(
                        tilemap_position,
                        tile_map)
            var floor_surface := surface_store.get_surface_for_tile(
                    tile_map,
                    tilemap_index,
                    SurfaceSide.FLOOR)
            var ceiling_surface := surface_store.get_surface_for_tile(
                    tile_map,
                    tilemap_index,
                    SurfaceSide.CEILING)
            var left_wall_surface := surface_store.get_surface_for_tile(
                    tile_map,
                    tilemap_index,
                    SurfaceSide.LEFT_WALL)
            var right_wall_surface := surface_store.get_surface_for_tile(
                    tile_map,
                    tilemap_index,
                    SurfaceSide.RIGHT_WALL)
            
            if is_instance_valid(floor_surface) and \
                    Sc.geometry.do_surface_and_rectangle_intersect(
                        floor_surface,
                        mark_cell_min_world_coords,
                        mark_cell_max_world_coords):
                surface_mark.add_surface(floor_surface)
            if is_instance_valid(ceiling_surface) and \
                    Sc.geometry.do_surface_and_rectangle_intersect(
                        ceiling_surface,
                        mark_cell_min_world_coords,
                        mark_cell_max_world_coords):
                surface_mark.add_surface(ceiling_surface)
            if is_instance_valid(left_wall_surface) and \
                    Sc.geometry.do_surface_and_rectangle_intersect(
                        left_wall_surface,
                        mark_cell_min_world_coords,
                        mark_cell_max_world_coords):
                surface_mark.add_surface(left_wall_surface)
            if is_instance_valid(right_wall_surface) and \
                    Sc.geometry.do_surface_and_rectangle_intersect(
                        right_wall_surface,
                        mark_cell_min_world_coords,
                        mark_cell_max_world_coords):
                surface_mark.add_surface(right_wall_surface)
