extends Reference
class_name PlatformGraphNodes

const Stopwatch = preload("res://framework/stopwatch.gd")

# TODO: Map the TileMap into an RTree or QuadTree.

var _stopwatch: Stopwatch

# Collections of surfaces.
# Array<PoolVector2Array>
var floors := []
var ceilings := []
var left_walls := []
var right_walls := []

# This supports mapping a cell in a TileMap to its corresponding surface.
# Dictionary<TileMap, Dictionary<String, Dictionary<int, PoolVector2Array>>>
var _tile_map_index_to_surface_maps := {}

func _init(tile_maps: Array) -> void:
    _stopwatch = Stopwatch.new()
    for tile_map in tile_maps:
        parse_tile_map(tile_map)

# Gets the surface corresponding to the given side of the given tile in the given TileMap.
func get_surface_for_tile(tile_map: TileMap, tile_map_index: int, \
        side: String) -> PoolVector2Array:
    return _tile_map_index_to_surface_maps[tile_map][side][tile_map_index]

# Parses the given TileMap into a set of nodes for the platform graph.
# 
# - Each "connecting" tile from the TileMap will be merged into a single surface node in the graph.
# - Each node in this graph corresponds to a continuous surface that could be walked on or climbed
#   on (i.e., floors and walls).
# - Each edge in this graph corresponds to a possible movement that the player could take to get
#   from one surface to another.
# 
# Assumptions:
# - The given TileMap only uses collidable tiles. Use a separate TileMap to paint any
#   non-collidable tiles.
# - The given TileMap only uses tiles with convex collision boundaries.
func parse_tile_map(tile_map: TileMap) -> void:
    var floors := []
    var ceilings := []
    var left_walls := []
    var right_walls := []
    
    _stopwatch.start()
    print("_parse_tile_map_into_sides...")
    _parse_tile_map_into_sides(tile_map, floors, ceilings, left_walls, right_walls)
    print("_parse_tile_map_into_sides duration: %sms" % _stopwatch.stop())
    
    _stopwatch.start()
    print("_remove_internal_surfaces: floors+ceilings...")
    _remove_internal_surfaces(floors, ceilings)
    print("_remove_internal_surfaces: left_walls+right_walls...")
    _remove_internal_surfaces(left_walls, right_walls)
    print("_remove_internal_surfaces duration: %sms" % _stopwatch.stop())
    
    _stopwatch.start()
    print("_merge_continuous_surfaces: floors...")
    _merge_continuous_surfaces(floors)
    print("_merge_continuous_surfaces: ceilings...")
    _merge_continuous_surfaces(ceilings)
    print("_merge_continuous_surfaces: left_walls...")
    _merge_continuous_surfaces(left_walls)
    print("_merge_continuous_surfaces: right_walls...")
    _merge_continuous_surfaces(right_walls)
    print("_merge_continuous_surfaces duration: %sms" % _stopwatch.stop())
    
    _stopwatch.start()
    print("_store_surfaces...")
    _store_surfaces(tile_map, floors, ceilings, left_walls, right_walls)
    print("_store_surfaces duration: %sms" % _stopwatch.stop())

# Parses the tiles of given TileMap into their constituent top-sides, left-sides, and right-sides.
func _parse_tile_map_into_sides(tile_map: TileMap, \
        floors: Array, ceilings: Array, left_walls: Array, right_walls: Array) -> void:
    var tile_set := tile_map.tile_set
    var cell_size := tile_map.cell_size
    var used_cells := tile_map.get_used_cells()
    
    for position in used_cells:
        var tile_map_index := Utils.get_tile_map_index_from_grid_coord(position, tile_map)
        
        # Transform tile shapes into world coordinates.
        var tile_set_index := tile_map.get_cellv(position)
        var info: Dictionary = tile_set.tile_get_shapes(tile_set_index)[0]
        # ConvexPolygonShape2D
        var shape: Shape2D = info.shape
        var shape_transform: Transform2D = info.shape_transform
        var vertex_count: int = shape.points.size()
        var tile_vertices_world_coords := Array()
        tile_vertices_world_coords.resize(vertex_count)
        for i in range(vertex_count):
            var vertex: Vector2 = shape.points[i]
            var vertex_world_coords: Vector2 = shape_transform.xform(vertex) + position * cell_size
            tile_vertices_world_coords[i] = vertex_world_coords
        
        # Calculate and store the polylines from this shape that correspond to the shape's
        # top-side, right-side, and left-side.
        _parse_polygon_into_sides(tile_vertices_world_coords, floors, ceilings, left_walls, \
                right_walls, tile_map_index)

# Parses the given polygon into separate polylines corresponding to the top-side, left-side, and
# right-side of the shape. Each of these polylines will be stored with their vertices in clockwise
# order.
func _parse_polygon_into_sides(vertices: Array, floors: Array, ceilings: Array, \
        left_walls: Array, right_walls: Array, tile_map_index: int) -> void:
    var vertex_count := vertices.size()
    var is_clockwise: bool = Utils.is_polygon_clockwise(vertices)
    
    # Find the left-most, right-most, and bottom-most vertices.
    
    var vertex_x: float
    var vertex_y: float
    var left_most_vertex_x: float = vertices[0].x
    var right_most_vertex_x: float = vertices[0].x
    var bottom_most_vertex_y: float = vertices[0].y
    var top_most_vertex_y: float = vertices[0].y
    var left_most_vertex_index := 0
    var right_most_vertex_index := 0
    var bottom_most_vertex_index := 0
    var top_most_vertex_index := 0
    
    for i in range(1, vertex_count):
        vertex_x = vertices[i].x
        vertex_y = vertices[i].y
        if vertex_x < left_most_vertex_x:
            left_most_vertex_x = vertex_x
            left_most_vertex_index = i
        if vertex_x > right_most_vertex_x:
            right_most_vertex_x = vertex_x
            right_most_vertex_index = i
        if vertex_y > bottom_most_vertex_y:
            bottom_most_vertex_y = vertex_y
            bottom_most_vertex_index = i
        if vertex_y < top_most_vertex_y:
            top_most_vertex_y = vertex_y
            top_most_vertex_index = i
    
    # Iterate across the edges in a clockwise direction, regardless of the order the vertices
    # are defined in.
    var step := 1 if is_clockwise else vertex_count - 1
    
    var i1: int
    var i2: int
    var v1: Vector2
    var v2: Vector2
    var pos_angle: float
    var is_wall_segment: bool
    
    var top_side_start_index: int
    var top_side_end_index: int
    var left_side_start_index: int
    var right_side_end_index: int
    
    # Find the start of the top-side.
    
    # Fence-post problem: Calculate the first segment.
    i1 = left_most_vertex_index
    i2 = (i1 + step) % vertex_count
    v1 = vertices[i1]
    v2 = vertices[i2]
    pos_angle = abs(v1.angle_to_point(v2))
    is_wall_segment = pos_angle > Utils.FLOOR_MAX_ANGLE and \
            pos_angle < PI - Utils.FLOOR_MAX_ANGLE
    
    # If we find a non-wall segment, that's the start of the top-side. If we instead find no
    # non-wall segments until one segment after the top-most vertex, then there is no
    # top-side, and we will treat the top-most vertex as both the start and end of this
    # degenerate-case "top-side".
    while is_wall_segment and i1 != top_most_vertex_index:
        i1 = i2
        i2 = (i1 + step) % vertex_count
        v1 = vertices[i1]
        v2 = vertices[i2]
        pos_angle = abs(v1.angle_to_point(v2))
        is_wall_segment = pos_angle > Utils.FLOOR_MAX_ANGLE and \
                pos_angle < PI - Utils.FLOOR_MAX_ANGLE
    
    top_side_start_index = i1
    
    # Find the end of the top-side.
    
    # If we find a wall segment, that's the end of the top-side. If we instead find no wall
    # segments until one segment after the right-most vertex, then there is no right-side, and
    # we will treat the right-most vertex as the end of the top-side.
    while !is_wall_segment and i1 != right_most_vertex_index:
        i1 = i2
        i2 = (i1 + step) % vertex_count
        v1 = vertices[i1]
        v2 = vertices[i2]
        pos_angle = abs(v1.angle_to_point(v2))
        is_wall_segment = pos_angle > Utils.FLOOR_MAX_ANGLE and \
                pos_angle < PI - Utils.FLOOR_MAX_ANGLE
    
    top_side_end_index = i1
    
    # Find the end of the right-side.
    
    # If we find a non-wall segment, that's the end of the right-side. If we instead find no
    # non-wall segments until one segment after the bottom-most vertex, then there is no
    # bottom-side, and we will treat the bottom-most vertex as end of the bottom-side.
    while is_wall_segment and i1 != bottom_most_vertex_index:
        i1 = i2
        i2 = (i1 + step) % vertex_count
        v1 = vertices[i1]
        v2 = vertices[i2]
        pos_angle = abs(v1.angle_to_point(v2))
        is_wall_segment = pos_angle > Utils.FLOOR_MAX_ANGLE and \
                pos_angle < PI - Utils.FLOOR_MAX_ANGLE
    
    right_side_end_index = i1
    
    # Find the start of the left-side.
    
    # If we find a wall segment, that's the start of the left-side. If we instead find no wall
    # segments until one segment after the left-most vertex, then there is no left-side, and we
    # will treat the left-most vertex as both the start and end of this degenerate-case
    # "left-side".
    while !is_wall_segment and i1 != left_most_vertex_index:
        i1 = i2
        i2 = (i1 + step) % vertex_count
        v1 = vertices[i1]
        v2 = vertices[i2]
        pos_angle = abs(v1.angle_to_point(v2))
        is_wall_segment = pos_angle > Utils.FLOOR_MAX_ANGLE and \
                pos_angle < PI - Utils.FLOOR_MAX_ANGLE
    
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
    var floor_surface = Surface.new()
    floor_surface.vertices_array = top_side_vertices
    floor_surface.tile_map_indices = [tile_map_index]
    var ceiling_surface = Surface.new()
    ceiling_surface.vertices_array = bottom_side_vertices
    ceiling_surface.tile_map_indices = [tile_map_index]
    var left_side_surface = Surface.new()
    left_side_surface.vertices_array = right_side_vertices
    left_side_surface.tile_map_indices = [tile_map_index]
    var right_side_surface = Surface.new()
    right_side_surface.vertices_array = left_side_vertices
    right_side_surface.tile_map_indices = [tile_map_index]
    
    floors.push_back(floor_surface)
    ceilings.push_back(ceiling_surface)
    left_walls.push_back(left_side_surface)
    right_walls.push_back(right_side_surface)

# Removes some "internal" surfaces.
# 
# Specifically, this checks for pairs of floor+ceiling segments or left-wall+right-wall segments
# that share the same vertices. Both segments in these pairs are considered internal, and are
# removed.
# 
# Any surface polyline that consists of more than one segment is ignored.
func _remove_internal_surfaces(surfaces: Array, opposite_surfaces: Array) -> void:
    var i: int
    var j: int
    var count_i: int
    var count_j: int
    var surface1: Surface
    var surface2: Surface
    var surface1_front: Vector2
    var surface1_back: Vector2
    var surface2_front: Vector2
    var surface2_back: Vector2
    var front_back_diff_x: float
    var front_back_diff_y: float
    var back_front_diff_x: float
    var back_front_diff_y: float
    
    count_i = surfaces.size()
    count_j = opposite_surfaces.size()
    i = 0
    while i < count_i:
        surface1 = surfaces[i]
        
        if surface1.vertices_array.size() > 2:
            i += 1
            continue
        
        surface1_front = surface1.vertices_array.front()
        surface1_back = surface1.vertices_array.back()
        
        j = 0
        while j < count_j:
            surface2 = opposite_surfaces[j]
            
            if surface2.vertices_array.size() > 2:
                j += 1
                continue
            
            surface2_front = surface2.vertices_array.front()
            surface2_back = surface2.vertices_array.back()
            
            # Vector equality checks, allowing for some round-off error.
            front_back_diff_x = surface1_front.x - surface2_back.x
            front_back_diff_y = surface1_front.y - surface2_back.y
            back_front_diff_x = surface1_back.x - surface2_front.x
            back_front_diff_y = surface1_back.y - surface2_front.y
            if front_back_diff_x < Utils.FLOAT_EPSILON and \
                    front_back_diff_x > -Utils.FLOAT_EPSILON and \
                    front_back_diff_y < Utils.FLOAT_EPSILON and \
                    front_back_diff_y > -Utils.FLOAT_EPSILON and \
                    back_front_diff_x < Utils.FLOAT_EPSILON and \
                    back_front_diff_x > -Utils.FLOAT_EPSILON and \
                    back_front_diff_y < Utils.FLOAT_EPSILON and \
                    back_front_diff_y > -Utils.FLOAT_EPSILON:
                # We found a pair of equivalent (internal) segments, so remove them.
                surfaces.remove(i)
                opposite_surfaces.remove(j)
                surface1.free()
                surface2.free()
                
                i -= 1
                j -= 1
                count_i -= 1
                count_j -= 1
                break
            
            j += 1
        
        i += 1

# Merges adjacent continuous surfaces.
func _merge_continuous_surfaces(surfaces: Array) -> void:
    var i: int
    var j: int
    var count: int
    var surface1: Surface
    var surface2: Surface
    var surface1_front: Vector2
    var surface1_back: Vector2
    var surface2_front: Vector2
    var surface2_back: Vector2
    var front_back_diff_x: float
    var front_back_diff_y: float
    var back_front_diff_x: float
    var back_front_diff_y: float
    var tile_map_index_1: int
    var tile_map_index_2: int
    
    var merge_count := 1
    while merge_count > 0:
        merge_count = 0
        count = surfaces.size()
        i = 0
        while i < count:
            surface1 = surfaces[i]
            surface1_front = surface1.vertices_array.front()
            surface1_back = surface1.vertices_array.back()
            
            j = i + 1
            while j < count:
                surface2 = surfaces[j]
                surface2_front = surface2.vertices_array.front()
                surface2_back = surface2.vertices_array.back()
                
                # Vector equality checks, allowing for some round-off error.
                front_back_diff_x = surface1_front.x - surface2_back.x
                front_back_diff_y = surface1_front.y - surface2_back.y
                back_front_diff_x = surface1_back.x - surface2_front.x
                back_front_diff_y = surface1_back.y - surface2_front.y
                if front_back_diff_x < Utils.FLOAT_EPSILON and \
                        front_back_diff_x > -Utils.FLOAT_EPSILON and \
                        front_back_diff_y < Utils.FLOAT_EPSILON and \
                        front_back_diff_y > -Utils.FLOAT_EPSILON:
                    # The start of surface 1 connects with the end of surface 2.
                    
                    # Merge the two surfaces, replacing the first surface and removing the second
                    # surface.
                    surface2.vertices_array.pop_back()
                    Utils.concat(surface2.vertices_array, surface1.vertices_array)
                    Utils.concat(surface2.tile_map_indices, surface1.tile_map_indices)
                    surfaces.remove(j)
                    surface1.free()
                    surfaces[i] = surface2
                    surface1 = surface2
                    surface1_front = surface1.vertices_array.front()
                    surface1_back = surface1.vertices_array.back()
                                        
                    j -= 1
                    count -= 1
                    merge_count += 1
                elif back_front_diff_x < Utils.FLOAT_EPSILON and \
                        back_front_diff_x > -Utils.FLOAT_EPSILON and \
                        back_front_diff_y < Utils.FLOAT_EPSILON and \
                        back_front_diff_y > -Utils.FLOAT_EPSILON:
                    # The end of surface 1 connects with the start of surface 2.
                    
                    # Merge the two surfaces, replacing the first surface and removing the second
                    # surface.
                    surface1.vertices_array.pop_back()
                    Utils.concat(surface1.vertices_array, surface2.vertices_array)
                    Utils.concat(surface1.tile_map_indices, surface2.tile_map_indices)
                    surfaces.remove(j)
                    surface2.free()
                    
                    j -= 1
                    count -= 1
                    merge_count += 1
                
                j += 1
            
            i += 1

func _store_surfaces(tile_map: TileMap, floors: Array, ceilings: Array, left_walls: Array, \
        right_walls: Array) -> void:
    _store_polyline_arrays(floors, self.floors)
    _store_polyline_arrays(ceilings, self.ceilings)
    _store_polyline_arrays(left_walls, self.left_walls)
    _store_polyline_arrays(right_walls, self.right_walls)
    
    var floor_mapping = _create_tile_map_mapping_from_surfaces(floors)
    var ceiling_mapping = _create_tile_map_mapping_from_surfaces(ceilings)
    var left_wall_mapping = _create_tile_map_mapping_from_surfaces(left_walls)
    var right_wall_mapping = _create_tile_map_mapping_from_surfaces(right_walls)
    
    _tile_map_index_to_surface_maps[tile_map] = {
        floor = floor_mapping,
        ceiling = ceiling_mapping,
        left_wall = left_wall_mapping,
        right_wall = right_wall_mapping,
    }

func _store_polyline_arrays(surfaces: Array, main_collection: Array) -> void:
    var pool_array: PoolVector2Array
    for surface in surfaces:
        pool_array = PoolVector2Array(surface.vertices_array)
        surface.vertices_pool_array = pool_array
        main_collection.push_back(pool_array)

func _create_tile_map_mapping_from_surfaces(surfaces: Array) -> Dictionary:
    var result = {}
    for surface in surfaces:
        for tile_map_index in surface.tile_map_indices:
            result[tile_map_index] = surface.vertices_pool_array
    return result

class Surface extends Object:
    # Array<Vector2>
    var vertices_array: Array
    var vertices_pool_array: PoolVector2Array
    # Array<int>
    var tile_map_indices: Array
