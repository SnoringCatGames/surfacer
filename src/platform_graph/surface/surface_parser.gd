class_name SurfaceParser
extends Reference


# TODO: Map the TileMap into an RTree or QuadTree.

const SURFACES_TILE_MAPS_COLLISION_LAYER := 1

const CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET := 0.02
const CORNER_TARGET_MORE_PREFERRED_SURFACE_SIDE_OFFSET := 0.01

const _EQUAL_POINT_EPSILON := 0.1

# Collections of surfaces.
# Array<Surface>
var floors := []
var ceilings := []
var left_walls := []
var right_walls := []

var all_surfaces := []
var non_ceiling_surfaces := []
var non_floor_surfaces := []
var non_wall_surfaces := []
var all_walls := []

var max_tile_map_cell_size: Vector2
var combined_tile_map_rect: Rect2

# This supports mapping a cell in a TileMap to its corresponding surface.
# Dictionary<SurfacesTileMap, Dictionary<String, Dictionary<int, Surface>>>
var _tile_map_index_to_surface_maps := {}

var _space_state: Physics2DDirectSpaceState
var _collision_tile_map_coord_result := CollisionTileMapCoordResult.new()


func calculate(tile_maps: Array) -> void:
    assert(!tile_maps.empty())
    
    # TODO: Add support for more than one collidable TileMap.
    assert(tile_maps.size() == 1)
    
    self._space_state = tile_maps[0].get_world_2d().direct_space_state
    
    # Record the maximum cell size and combined region from all tile maps.
    _calculate_max_tile_map_cell_size(tile_maps)
    _calculate_combined_tile_map_rect(tile_maps)
    
    for tile_map in tile_maps:
        _parse_tile_map(tile_map)


# Gets the surface corresponding to the given side of the given tile in the
# given TileMap.
func get_surface_for_tile(
        tile_map: SurfacesTileMap,
        tile_map_index: int,
        side: int) -> Surface:
    var _tile_map_index_to_surfaces: Dictionary = \
            _tile_map_index_to_surface_maps[tile_map][side]
    if _tile_map_index_to_surfaces.has(tile_map_index):
        return _tile_map_index_to_surfaces[tile_map_index]
    else:
        return null


func get_subset_of_surfaces(
        include_walls: bool,
        include_ceilings: bool,
        include_floors: bool) -> Array:
    if include_walls:
        if include_ceilings:
            if include_floors:
                return all_surfaces
            else:
                return non_floor_surfaces
        else:
            if include_floors:
                return non_ceiling_surfaces
            else:
                return all_walls
    else:
        if include_ceilings:
            if include_floors:
                return non_wall_surfaces
            else:
                return ceilings
        else:
            if include_floors:
                return floors
            else:
                return []


func _calculate_max_tile_map_cell_size(tile_maps: Array) -> void:
    max_tile_map_cell_size = Vector2.ZERO
    for tile_map in tile_maps:
        if tile_map.cell_size.x + tile_map.cell_size.y > \
                max_tile_map_cell_size.x + max_tile_map_cell_size.y:
            max_tile_map_cell_size = tile_map.cell_size


func _calculate_combined_tile_map_rect(tile_maps: Array) -> void:
    combined_tile_map_rect = \
            Sc.geometry.get_tile_map_bounds_in_world_coordinates(tile_maps[0])
    for tile_map in tile_maps:
        combined_tile_map_rect = combined_tile_map_rect.merge(
                Sc.geometry.get_tile_map_bounds_in_world_coordinates(tile_map))


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
func _parse_tile_map(tile_map: SurfacesTileMap) -> void:
    var floors := []
    var ceilings := []
    var left_walls := []
    var right_walls := []
    
    Sc.profiler.start("validate_tile_set_duration")
    _validate_tile_set(tile_map)
    Sc.profiler.stop("validate_tile_set_duration")
    
    Sc.profiler.start("parse_tile_map_into_sides_duration")
    _parse_tile_map_into_sides(
            tile_map,
            floors,
            ceilings,
            left_walls,
            right_walls)
    Sc.profiler.stop("parse_tile_map_into_sides_duration")
    
    Sc.profiler.start("remove_internal_surfaces_duration")
    _remove_internal_surfaces(
            floors,
            ceilings)
    _remove_internal_surfaces(
            left_walls,
            right_walls)
    Sc.profiler.stop("remove_internal_surfaces_duration")
    
    Sc.profiler.start("merge_continuous_surfaces_duration")
    _merge_continuous_surfaces(floors)
    _merge_continuous_surfaces(ceilings)
    _merge_continuous_surfaces(left_walls)
    _merge_continuous_surfaces(right_walls)
    Sc.profiler.stop("merge_continuous_surfaces_duration")
    
    Sc.profiler.start("remove_internal_collinear_vertices_duration")
    _remove_internal_collinear_vertices(floors)
    _remove_internal_collinear_vertices(ceilings)
    _remove_internal_collinear_vertices(left_walls)
    _remove_internal_collinear_vertices(right_walls)
    Sc.profiler.stop("remove_internal_collinear_vertices_duration")
    
    Sc.profiler.start("store_surfaces_duration")
    _store_surfaces(
            tile_map,
            floors,
            ceilings,
            left_walls,
            right_walls)
    Sc.profiler.stop("store_surfaces_duration")
    
    Sc.profiler.start("populate_derivative_collections")
    _populate_derivative_collections(tile_map)
    Sc.profiler.stop("populate_derivative_collections")
    
    Sc.profiler.start("assign_neighbor_surfaces_duration")
    _assign_neighbor_surfaces(
            self.floors,
            self.ceilings,
            self.left_walls,
            self.right_walls)
    Sc.profiler.stop("assign_neighbor_surfaces_duration")
    
    Sc.profiler.start("calculate_shape_bounding_boxes_for_surfaces_duration")
    # Since this calculation will loop around transitive neigbors, and since
    # every surface should be connected transitively to a floor, it should also
    # end up recording the bounding box for all other surface sides too.
    _calculate_shape_bounding_boxes_for_surfaces(self.floors)
    Sc.profiler.stop("calculate_shape_bounding_boxes_for_surfaces_duration")
    
    Sc.profiler.start("assert_surfaces_fully_calculated_duration")
    _assert_surfaces_fully_calculated(self.floors)
    _assert_surfaces_fully_calculated(self.ceilings)
    _assert_surfaces_fully_calculated(self.left_walls)
    _assert_surfaces_fully_calculated(self.right_walls)
    Sc.profiler.stop("assert_surfaces_fully_calculated_duration")


func _store_surfaces(
        tile_map: SurfacesTileMap,
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
            self.floors)
    _copy_surfaces_to_main_collection(
            ceilings,
            self.ceilings)
    _copy_surfaces_to_main_collection(
            left_walls,
            self.left_walls)
    _copy_surfaces_to_main_collection(
            right_walls,
            self.right_walls)
    
    _free_objects(floors)
    _free_objects(ceilings)
    _free_objects(left_walls)
    _free_objects(right_walls)


func _populate_derivative_collections(tile_map: SurfacesTileMap) -> void:
    # TODO: This is broken with multiple tilemaps.
    all_surfaces = []
    Sc.utils.concat(
            all_surfaces,
            self.floors)
    Sc.utils.concat(
            all_surfaces,
            self.right_walls)
    Sc.utils.concat(
            all_surfaces,
            self.left_walls)
    Sc.utils.concat(
            all_surfaces,
            self.ceilings)
    non_ceiling_surfaces = []
    Sc.utils.concat(
            non_ceiling_surfaces,
            self.floors)
    Sc.utils.concat(
            non_ceiling_surfaces,
            self.right_walls)
    Sc.utils.concat(
            non_ceiling_surfaces,
            self.left_walls)
    non_floor_surfaces = []
    Sc.utils.concat(
            non_floor_surfaces,
            self.right_walls)
    Sc.utils.concat(
            non_floor_surfaces,
            self.left_walls)
    Sc.utils.concat(
            non_floor_surfaces,
            self.ceilings)
    non_wall_surfaces = []
    Sc.utils.concat(
            non_wall_surfaces,
            self.floors)
    Sc.utils.concat(
            non_wall_surfaces,
            self.ceilings)
    all_walls = []
    Sc.utils.concat(
            all_walls,
            self.right_walls)
    Sc.utils.concat(
            all_walls,
            self.left_walls)
    
    var floor_mapping = _create_tile_map_mapping_from_surfaces(self.floors)
    var ceiling_mapping = _create_tile_map_mapping_from_surfaces(self.ceilings)
    var left_wall_mapping = \
            _create_tile_map_mapping_from_surfaces(self.left_walls)
    var right_wall_mapping = \
            _create_tile_map_mapping_from_surfaces(self.right_walls)
    
    self._tile_map_index_to_surface_maps[tile_map] = {
        SurfaceSide.FLOOR: floor_mapping,
        SurfaceSide.CEILING: ceiling_mapping,
        SurfaceSide.LEFT_WALL: left_wall_mapping,
        SurfaceSide.RIGHT_WALL: right_wall_mapping,
    }


static func _validate_tile_set(tile_map: SurfacesTileMap) -> void:
    var tile_set := tile_map.tile_set
    assert(is_instance_valid(tile_set))
    
    var ids := tile_set.get_tiles_ids()
    assert(ids.size() > 0)
    
    for id in ids:
        var shapes := tile_set.tile_get_shapes(id)
        assert(shapes.size() <= 1)
        
        if shapes.size() == 0:
            continue
        
        var info: Dictionary = shapes[0]
        var shape: Shape2D = info.shape
        var shape_transform: Transform2D = info.shape_transform
        
        assert(shape is ConvexPolygonShape2D,
                "TileSet collision shapes must be of type " +
                "ConvexPolygonShape2D.")
        
        var points: PoolVector2Array = shape.points
        
        for i in points.size() - 1:
            assert(points[i] != points[i + 1],
                    "TileSet collision shapes must not have " +
                    "duplicated vertices.")
        
        for i in points.size():
            assert(points[i].x == int(points[i].x) and \
                    points[i].y == int(points[i].y), 
                    "TileSet collision-shape vertices must align with " +
                    "whole-pixel coordinates (this is important for merging " +
                    "adjacent-tile surfaces).")


# Parses the tiles of given TileMap into their constituent top-sides,
# left-sides, and right-sides.
static func _parse_tile_map_into_sides(
        tile_map: SurfacesTileMap,
        floors: Array,
        ceilings: Array,
        left_walls: Array,
        right_walls: Array) -> void:
    var tile_set := tile_map.tile_set
    var cell_size := tile_map.cell_size
    var used_cells := tile_map.get_used_cells()
    
    for position in used_cells:
        var tile_map_index: int = \
                Sc.geometry.get_tile_map_index_from_grid_coord(
                        position,
                        tile_map)
        var tile_set_index := tile_map.get_cellv(position)
        var shapes := tile_set.tile_get_shapes(tile_set_index)
        if shapes.empty():
            # This is a non-collidable tile (usually a background tile).
            continue
        var info: Dictionary = shapes[0]
        
        # Transform tile shapes into world coordinates.
        
        # ConvexPolygonShape2D
        var shape: Shape2D = info.shape
        var shape_transform: Transform2D = info.shape_transform
        var vertex_count: int = shape.points.size()
        var tile_vertices_world_coords := Array()
        tile_vertices_world_coords.resize(vertex_count)
        for i in vertex_count:
            var vertex: Vector2 = shape.points[i]
            var vertex_world_coords: Vector2 = \
                    shape_transform.xform(vertex) + position * cell_size
            tile_vertices_world_coords[i] = vertex_world_coords
        
        # Calculate and store the polylines from this shape that correspond to
        # the shape's top-side, right-side, and left-side.
        _parse_polygon_into_sides(
                tile_vertices_world_coords,
                floors,
                ceilings,
                left_walls,
                right_walls,
                tile_map,
                tile_map_index)


# Parses the given polygon into separate polylines corresponding to the
# top-side, left-side, and right-side of the shape. Each of these polylines
# will be stored with their vertices in clockwise order.
static func _parse_polygon_into_sides(
        vertices: Array,
        floors: Array,
        ceilings: Array,
        left_walls: Array,
        right_walls: Array,
        tile_map: SurfacesTileMap,
        tile_map_index: int) -> void:
    var vertex_count := vertices.size()
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
    
    var WALL_ANGLE_EPSILON := 0.0001
    var FLOOR_MAX_ANGLE_BELOW_90: float = \
            Sc.geometry.FLOOR_MAX_ANGLE + WALL_ANGLE_EPSILON
    var FLOOR_MIN_ANGLE_ABOVE_90: float = \
            PI - Sc.geometry.FLOOR_MAX_ANGLE - WALL_ANGLE_EPSILON
    
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
    
    # Store the surfaces.
    var floor_surface = _TmpSurface.new()
    floor_surface.vertices_array = top_side_vertices
    floor_surface.tile_map = tile_map
    floor_surface.tile_map_indices = [tile_map_index]
    var ceiling_surface = _TmpSurface.new()
    ceiling_surface.vertices_array = bottom_side_vertices
    ceiling_surface.tile_map = tile_map
    ceiling_surface.tile_map_indices = [tile_map_index]
    var left_side_surface = _TmpSurface.new()
    left_side_surface.vertices_array = right_side_vertices
    left_side_surface.tile_map = tile_map
    left_side_surface.tile_map_indices = [tile_map_index]
    var right_side_surface = _TmpSurface.new()
    right_side_surface.vertices_array = left_side_vertices
    right_side_surface.tile_map = tile_map
    right_side_surface.tile_map_indices = [tile_map_index]
    
    floors.push_back(floor_surface)
    ceilings.push_back(ceiling_surface)
    left_walls.push_back(left_side_surface)
    right_walls.push_back(right_side_surface)


# Removes some "internal" surfaces.
# 
# Specifically, this checks for pairs of floor+ceiling segments or
# left-wall+right-wall segments that share the same vertices. Both segments in
# these pairs are considered internal, and are removed.
# 
# Any surface polyline that consists of more than one segment is ignored.
static func _remove_internal_surfaces(
        surfaces: Array,
        opposite_surfaces: Array) -> void:
    var removal_count := 0
    var count_i := surfaces.size()
    var count_j := opposite_surfaces.size()
    var i := 0
    
    while i < count_i:
        var surface1: _TmpSurface = surfaces[i]
        
        if surface1.vertices_array.size() > 2:
            i += 1
            continue
        
        var surface1_front: Vector2 = surface1.vertices_array.front()
        var surface1_back: Vector2 = surface1.vertices_array.back()
        
        var j := 0
        while j < count_j:
            var surface2: _TmpSurface = opposite_surfaces[j]
            
            if surface2 == null or \
                    surface2.vertices_array.size() > 2:
                j += 1
                continue
            
            var surface2_front: Vector2 = surface2.vertices_array.front()
            var surface2_back: Vector2 = surface2.vertices_array.back()
            
            # Vector equality checks, allowing for some round-off error.
            var front_back_diff_x := surface1_front.x - surface2_back.x
            var front_back_diff_y := surface1_front.y - surface2_back.y
            var back_front_diff_x := surface1_back.x - surface2_front.x
            var back_front_diff_y := surface1_back.y - surface2_front.y
            if front_back_diff_x < _EQUAL_POINT_EPSILON and \
                    front_back_diff_x > -_EQUAL_POINT_EPSILON and \
                    front_back_diff_y < _EQUAL_POINT_EPSILON and \
                    front_back_diff_y > -_EQUAL_POINT_EPSILON and \
                    back_front_diff_x < _EQUAL_POINT_EPSILON and \
                    back_front_diff_x > -_EQUAL_POINT_EPSILON and \
                    back_front_diff_y < _EQUAL_POINT_EPSILON and \
                    back_front_diff_y > -_EQUAL_POINT_EPSILON:
                # We found a pair of equivalent (internal) segments, so remove
                # them.
                surfaces[i] = null
                opposite_surfaces[j] = null
                surface1.free()
                surface2.free()
                removal_count += 1
                break
            
            j += 1
        
        i += 1
    
    # Resize surfaces array, removing any deleted elements.
    var new_index := 0
    for old_index in count_i:
        var surface: _TmpSurface = surfaces[old_index]
        if surface != null:
            surfaces[new_index] = surface
            new_index += 1
    surfaces.resize(count_i - removal_count)
    
    # Resize surfaces array, removing any deleted elements.
    new_index = 0
    for old_index in count_j:
        var surface: _TmpSurface = opposite_surfaces[old_index]
        if surface != null:
            opposite_surfaces[new_index] = surface
            new_index += 1
    opposite_surfaces.resize(count_j - removal_count)


# Merges adjacent continuous surfaces.
static func _merge_continuous_surfaces(surfaces: Array) -> void:
    var merge_count := 1
    while merge_count > 0:
        merge_count = 0
        var count := surfaces.size()
        var i := 0
        while i < count:
            var surface1: _TmpSurface = surfaces[i]
            var surface1_front: Vector2 = surface1.vertices_array.front()
            var surface1_back: Vector2 = surface1.vertices_array.back()
            
            var j := i + 1
            while j < count:
                var surface2: _TmpSurface = surfaces[j]
                var surface2_front: Vector2 = surface2.vertices_array.front()
                var surface2_back: Vector2 = surface2.vertices_array.back()
                
                # Vector equality checks, allowing for some round-off error.
                var front_back_diff_x := surface1_front.x - surface2_back.x
                var front_back_diff_y := surface1_front.y - surface2_back.y
                var back_front_diff_x := surface1_back.x - surface2_front.x
                var back_front_diff_y := surface1_back.y - surface2_front.y
                if front_back_diff_x < _EQUAL_POINT_EPSILON and \
                        front_back_diff_x > -_EQUAL_POINT_EPSILON and \
                        front_back_diff_y < _EQUAL_POINT_EPSILON and \
                        front_back_diff_y > -_EQUAL_POINT_EPSILON:
                    # The start of surface 1 connects with the end of surface
                    # 2.
                    
                    # Merge the two surfaces, replacing the first surface and
                    # removing the second surface.
                    surface2.vertices_array.pop_back()
                    Sc.utils.concat(
                            surface2.vertices_array,
                            surface1.vertices_array)
                    Sc.utils.concat(
                            surface2.tile_map_indices,
                            surface1.tile_map_indices)
                    surfaces.remove(j)
                    surface1.free()
                    surfaces[i] = surface2
                    surface1 = surface2
                    surface1_front = surface1.vertices_array.front()
                    surface1_back = surface1.vertices_array.back()
                                        
                    j -= 1
                    count -= 1
                    merge_count += 1
                elif back_front_diff_x < _EQUAL_POINT_EPSILON and \
                        back_front_diff_x > -_EQUAL_POINT_EPSILON and \
                        back_front_diff_y < _EQUAL_POINT_EPSILON and \
                        back_front_diff_y > -_EQUAL_POINT_EPSILON:
                    # The end of surface 1 connects with the start of surface
                    # 2.
                    
                    # Merge the two surfaces, replacing the first surface and
                    # removing the second surface.
                    surface1.vertices_array.pop_back()
                    Sc.utils.concat(
                            surface1.vertices_array,
                            surface2.vertices_array)
                    Sc.utils.concat(
                            surface1.tile_map_indices,
                            surface2.tile_map_indices)
                    surfaces.remove(j)
                    surface2.free()
                    
                    j -= 1
                    count -= 1
                    merge_count += 1
                
                j += 1
            
            i += 1


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
                if floor_surface.counter_clockwise_convex_neighbor != \
                                null and \
                        floor_surface.clockwise_concave_neighbor != null:
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
                if floor_surface.counter_clockwise_convex_neighbor != \
                                null and \
                        floor_surface.clockwise_concave_neighbor != null:
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
                if floor_surface.counter_clockwise_concave_neighbor != \
                                null and \
                        floor_surface.clockwise_convex_neighbor != null:
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
                if floor_surface.counter_clockwise_concave_neighbor != \
                                null and \
                        floor_surface.clockwise_convex_neighbor != null:
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
                if ceiling.counter_clockwise_convex_neighbor != \
                                null and \
                        ceiling.clockwise_concave_neighbor != null:
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
                if ceiling.counter_clockwise_convex_neighbor != \
                                null and \
                        ceiling.clockwise_concave_neighbor != null:
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
                if ceiling.counter_clockwise_concave_neighbor != \
                                null and \
                        ceiling.clockwise_convex_neighbor != null:
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
                if ceiling.counter_clockwise_concave_neighbor != \
                                null and \
                        ceiling.clockwise_convex_neighbor != null:
                    break
    
    # FIXME: LEFT OFF HERE: ----------------- Still not quite perfect yet?
    
    # -   If surfaces align with the FLOOR_MAX_ANGLE, then it is possible for a
    #     floor to be adjacent to a ceiling.
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


static func _assert_surfaces_fully_calculated(surfaces: Array) -> void:
    for surface in surfaces:
        assert(surface.clockwise_neighbor != null)
        assert(surface.counter_clockwise_neighbor != null)
        assert(surface.connected_region_bounding_box.position != \
                Vector2.INF and \
                surface.connected_region_bounding_box.size != Vector2.INF)


static func _populate_surface_objects(
        tmp_surfaces: Array,
        side: int) -> void:
    for tmp_surface in tmp_surfaces:
        tmp_surface.surface = Surface.new(
                tmp_surface.vertices_array,
                side,
                tmp_surface.tile_map,
                tmp_surface.tile_map_indices)


static func _copy_surfaces_to_main_collection(
        tmp_surfaces: Array,
        main_collection: Array) -> void:
    for tmp_surface in tmp_surfaces:
        main_collection.push_back(tmp_surface.surface)


static func _create_tile_map_mapping_from_surfaces(
        surfaces: Array) -> Dictionary:
    var result = {}
    for surface in surfaces:
        for tile_map_index in surface.tile_map_indices:
            result[tile_map_index] = surface
    return result


static func _free_objects(objects: Array) -> void:
    for object in objects:
        object.free()


class _TmpSurface extends Object:
    # Array<Vector2>
    var vertices_array: Array
    var tile_map: SurfacesTileMap
    # Array<int>
    var tile_map_indices: Array
    var surface: Surface


func find_closest_surface_in_direction(
        target: Vector2,
        direction: Vector2,
        collision_tile_map_coord_result: CollisionTileMapCoordResult = null,
        max_distance := 10000.0) -> Surface:
    collision_tile_map_coord_result = \
            collision_tile_map_coord_result if \
            collision_tile_map_coord_result != null else \
            _collision_tile_map_coord_result
    
    var collision: Dictionary = _space_state.intersect_ray(
            target,
            direction * max_distance,
            [],
            SURFACES_TILE_MAPS_COLLISION_LAYER,
            true,
            false)
    
    var contact_position: Vector2 = collision.position
    var contacted_side: int = \
            Sc.geometry.get_surface_side_for_normal(collision.normal)
    assert(collision.collider is SurfacesTileMap)
    var contacted_tile_map: SurfacesTileMap = collision.collider
    
    Sc.geometry.get_collision_tile_map_coord(
            collision_tile_map_coord_result,
            contact_position,
            contacted_tile_map,
            contacted_side == SurfaceSide.FLOOR,
            contacted_side == SurfaceSide.CEILING,
            contacted_side == SurfaceSide.LEFT_WALL,
            contacted_side == SurfaceSide.RIGHT_WALL)
    var contact_position_tile_map_coord := \
            collision_tile_map_coord_result.tile_map_coord
    
    var contacted_tile_map_index: int = \
            Sc.geometry.get_tile_map_index_from_grid_coord(
                    contact_position_tile_map_coord,
                    contacted_tile_map)
    
    return get_surface_for_tile(
            contacted_tile_map,
            contacted_tile_map_index,
            contacted_side)


static func find_closest_position_on_a_surface(
        target: Vector2,
        character,
        surface_reachability: int,
        max_distance_squared_threshold := INF,
        max_distance_basis_point := Vector2.INF) -> PositionAlongSurface:
    var surfaces
    match surface_reachability:
        SurfaceReachability.ANY:
            surfaces = character.possible_surfaces_set
        SurfaceReachability.REACHABLE:
            assert(Su.are_reachable_surfaces_per_player_tracked)
            surfaces = character.reachable_surfaces
        SurfaceReachability.REVERSIBLY_REACHABLE:
            assert(Su.are_reachable_surfaces_per_player_tracked)
            surfaces = character.reversibly_reachable_surfaces
        _:
            Sc.logger.error()
    
    var positions := find_closest_positions_on_surfaces(
            target,
            character,
            1,
            max_distance_squared_threshold,
            max_distance_basis_point,
            surfaces)
    if positions.empty():
        return null
    else:
        return positions[0]


static func find_closest_positions_on_surfaces(
        target: Vector2,
        character,
        position_count: int,
        max_distance_squared_threshold := INF,
        max_distance_basis_point := Vector2.INF,
        surfaces = []) -> Array:
    surfaces = \
                surfaces if \
                !surfaces.empty() else \
                character.possible_surfaces_set
    var closest_surfaces := get_closest_surfaces(
            target,
            surfaces,
            position_count,
            max_distance_squared_threshold,
            max_distance_basis_point)
    
    var closest_positions := []
    closest_positions.resize(closest_surfaces.size())
    
    for i in closest_surfaces.size():
        var position := PositionAlongSurface.new()
        position.match_surface_target_and_collider(
                closest_surfaces[i],
                target,
                character.movement_params.collider_half_width_height,
                true,
                true)
        closest_positions[i] = position
    
    return closest_positions


# Gets the closest surface to the given point.
static func get_closest_surfaces(
        target: Vector2,
        surfaces,
        surface_count: int,
        max_distance_squared_threshold := INF,
        max_distance_basis_point := Vector2.INF) -> Array:
    assert(!surfaces.empty())
    
    max_distance_basis_point = \
            max_distance_basis_point if \
            max_distance_basis_point != Vector2.INF else \
            target
    var next_distance_squared_to_beat := max_distance_squared_threshold
    var closest_surfaces_and_distances := []
    
    for current_surface in surfaces:
        var current_target_distance_squared: float = \
                Sc.geometry.distance_squared_from_point_to_rect(
                        target,
                        current_surface.bounding_box)
        var current_max_distance_basis_distance_squared: float = \
                Sc.geometry.distance_squared_from_point_to_rect(
                        max_distance_basis_point,
                        current_surface.bounding_box)
        if current_target_distance_squared < \
                        next_distance_squared_to_beat and \
                current_max_distance_basis_distance_squared < \
                        max_distance_squared_threshold:
            var closest_point: Vector2 = \
                    Sc.geometry.get_closest_point_on_polyline_to_point(
                            target,
                            current_surface.vertices)
            current_target_distance_squared = \
                    target.distance_squared_to(closest_point)
            current_max_distance_basis_distance_squared = \
                    max_distance_basis_point.distance_squared_to(closest_point)
            if current_target_distance_squared < \
                            next_distance_squared_to_beat and \
                    current_max_distance_basis_distance_squared < \
                            max_distance_squared_threshold:
                var is_closest_to_first_point: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                                closest_point,
                                current_surface.first_point,
                                0.01)
                var is_closest_to_last_point: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                                closest_point,
                                current_surface.last_point,
                                0.01)
                if is_closest_to_first_point or is_closest_to_last_point:
                    var first_point_diff: Vector2 = \
                            target - current_surface.first_point
                    var last_point_diff: Vector2 = \
                            target - current_surface.last_point
                    
                    var is_more_than_45_deg_from_normal_from_corner: bool
                    match current_surface.side:
                        SurfaceSide.FLOOR:
                            if is_closest_to_first_point:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        first_point_diff.x < 0.0 and \
                                        -first_point_diff.x > \
                                                -first_point_diff.y
                            else:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        last_point_diff.x > 0.0 and \
                                        last_point_diff.x > -last_point_diff.y
                        SurfaceSide.LEFT_WALL:
                            if is_closest_to_first_point:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        first_point_diff.y < 0.0 and \
                                        first_point_diff.x < \
                                                -first_point_diff.y
                            else:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        last_point_diff.y > 0.0 and \
                                        last_point_diff.x < last_point_diff.y
                        SurfaceSide.RIGHT_WALL:
                            if is_closest_to_first_point:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        first_point_diff.y > 0.0 and \
                                        -first_point_diff.x < \
                                                first_point_diff.y
                            else:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        last_point_diff.y < 0.0 and \
                                        -last_point_diff.x < -last_point_diff.y
                        SurfaceSide.CEILING:
                            if is_closest_to_first_point:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        first_point_diff.x > 0.0 and \
                                        first_point_diff.x > first_point_diff.y
                            else:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        last_point_diff.x < 0.0 and \
                                        -last_point_diff.x > last_point_diff.y
                        _:
                            Sc.logger.error("Invalid SurfaceSide")
                    
                    current_target_distance_squared += \
                            CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET if \
                            is_more_than_45_deg_from_normal_from_corner else \
                            CORNER_TARGET_MORE_PREFERRED_SURFACE_SIDE_OFFSET
                
                var was_added := maybe_add_surface_to_closest_n_collection(
                        closest_surfaces_and_distances,
                        [current_surface, current_target_distance_squared],
                        surface_count)
                if was_added:
                    next_distance_squared_to_beat = \
                            closest_surfaces_and_distances[ \
                                    surface_count - 1][1] if \
                            closest_surfaces_and_distances.size() == \
                                    surface_count else \
                            max_distance_squared_threshold
    
    var closest_surfaces := []
    closest_surfaces.resize(closest_surfaces_and_distances.size())
    for i in closest_surfaces_and_distances.size():
        closest_surfaces[i] = closest_surfaces_and_distances[i][0]
    
    return closest_surfaces


static func maybe_add_surface_to_closest_n_collection(
        collection: Array,
        surface_and_distance: Array,
        n: int) -> bool:
    if collection.size() < n:
        collection.push_back(surface_and_distance)
        collection.sort_custom(_SurfaceAndDistanceComparator, "sort_ascending")
        return true
    else:
        if surface_and_distance[1] < collection[n - 1][1]:
            collection[n - 1] = surface_and_distance
            collection.sort_custom(
                    _SurfaceAndDistanceComparator, "sort_ascending")
            return true
    return false


class _SurfaceAndDistanceComparator:
    static func sort_ascending(a: Array, b: Array):
        if a[1] < b[1]:
            return true
        return false


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    var tile_maps: Array = context.id_to_tile_map.values()
    _space_state = tile_maps[0].get_world_2d().direct_space_state
    _calculate_max_tile_map_cell_size(tile_maps)
    _calculate_combined_tile_map_rect(tile_maps)
    
    floors = _json_object_to_surface_array(json_object.floors, context)
    ceilings = _json_object_to_surface_array(json_object.ceilings, context)
    left_walls = _json_object_to_surface_array(json_object.left_walls, context)
    right_walls = \
            _json_object_to_surface_array(json_object.right_walls, context)
    
    # TODO: This is broken with multiple tilemaps.
    _populate_derivative_collections(tile_maps[0])
    
    for i in floors.size():
        floors[i].load_references_from_json_context(
                json_object.floors[i],
                context)
    for i in ceilings.size():
        ceilings[i].load_references_from_json_context(
                json_object.ceilings[i],
                context)
    for i in left_walls.size():
        left_walls[i].load_references_from_json_context(
                json_object.left_walls[i],
                context)
    for i in right_walls.size():
        right_walls[i].load_references_from_json_context(
                json_object.right_walls[i],
                context)


func to_json_object() -> Dictionary:
    return {
        floors = _surface_array_to_json_object(floors),
        ceilings = _surface_array_to_json_object(ceilings),
        left_walls = _surface_array_to_json_object(left_walls),
        right_walls = _surface_array_to_json_object(right_walls),
    }


func _json_object_to_surface_array(
        json_object: Array,
        context: Dictionary) -> Array:
    var result := []
    result.resize(json_object.size())
    for i in json_object.size():
        var surface := Surface.new()
        surface.load_from_json_object(
                json_object[i],
                context)
        result[i] = surface
    return result


func _surface_array_to_json_object(surfaces: Array) -> Array:
    var result := []
    result.resize(surfaces.size())
    for i in surfaces.size():
        result[i] = surfaces[i].to_json_object()
    return result
