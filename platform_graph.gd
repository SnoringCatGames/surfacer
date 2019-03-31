extends Reference
class_name PlatformGraph

# TODO: Map the TileMap into an RTree or QuadTree.

var floors := []
var left_walls := []
var right_walls := []

# Parses the given TileMap into a platform graph.
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
    # TODO:
    # - Print how long each step takes to run.
    # - Render annotations.
    
    print("_parse_tile_map_into_sides")
    _parse_tile_map_into_sides(tile_map)
    print("_merge_continuous_surfaces: floors")
    _merge_continuous_surfaces(floors)
    print("_merge_continuous_surfaces: left_walls")
    _merge_continuous_surfaces(left_walls)
    print("_merge_continuous_surfaces: right_walls")
    _merge_continuous_surfaces(right_walls)

# Parses the tiles of given TileMap into their constituent top-sides, left-sides, and right-sides.
func _parse_tile_map_into_sides(tile_map: TileMap) -> void:
    var tile_set := tile_map.tile_set
    var cell_size := tile_map.cell_size
    var used_cells := tile_map.get_used_cells()
    
    # Transform tile shapes into world coordinates.
    for position in used_cells:
        var tile_set_index := tile_map.get_cellv(position)
        var info: Dictionary = tile_set.tile_get_shapes(tile_set_index)[0]
        # ConvexPolygonShape2D
        var shape: Shape2D = info.shape
        var shape_transform: Transform2D = info.shape_transform
        var vertex_count: int = shape.points.size()

        # Transform shape vertices into world coordinates.
        var vertices_world_coords := Array()
        vertices_world_coords.resize(vertex_count)
        for i in range(vertex_count):
            var vertex: Vector2 = shape.points[i]
            var vertex_world_coords: Vector2 = shape_transform.xform(vertex) + position * cell_size
            vertices_world_coords[i] = vertex_world_coords
        
        # Calculate and store the polylines from this shape that correspond to the shape's
        # top-side, right-side, and left-side.
        _parse_polygon_into_sides(vertices_world_coords)

# Parses the given polygon into separate polylines corresponding to the top-side, left-side, and
# right-side of the shape. Each of these polylines will be stored with their vertices in clockwise
# order.
func _parse_polygon_into_sides(vertices: Array) -> void:
    var vertex_count := vertices.size()
    var is_clockwise := _is_polygon_clockwise(vertices)
    
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
    is_wall_segment = pos_angle > Global.FLOOR_MAX_ANGLE and \
            pos_angle < PI - Global.FLOOR_MAX_ANGLE
    
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
        is_wall_segment = pos_angle > Global.FLOOR_MAX_ANGLE and \
                pos_angle < PI - Global.FLOOR_MAX_ANGLE
    
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
        is_wall_segment = pos_angle > Global.FLOOR_MAX_ANGLE and \
                pos_angle < PI - Global.FLOOR_MAX_ANGLE
    
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
        is_wall_segment = pos_angle > Global.FLOOR_MAX_ANGLE and \
                pos_angle < PI - Global.FLOOR_MAX_ANGLE
    
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
        is_wall_segment = pos_angle > Global.FLOOR_MAX_ANGLE and \
                pos_angle < PI - Global.FLOOR_MAX_ANGLE
    
    left_side_start_index = i1
    
    var i: int
    
    # Calculate the polyline corresponding to the top side.
    
    var top_side_vertices := []
    i = top_side_start_index
    while i != top_side_end_index:
        top_side_vertices.push_back(vertices[i])
        i = (i + step) % vertex_count
    top_side_vertices.push_back(vertices[i])
    
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
    
    # Store the polylines.
    
    floors.push_back(top_side_vertices)
    left_walls.push_back(right_side_vertices)
    right_walls.push_back(left_side_vertices)

# Merges adjacent continuous surfaces.
func _merge_continuous_surfaces(surfaces: Array) -> void:
    var i: int
    var j: int
    var count: int
    var surface1: Array
    var surface2: Array
    var surface1_front: Vector2
    var surface1_back: Vector2
    var surface2_front: Vector2
    var surface2_back: Vector2
    var front_back_diff_x: float
    var front_back_diff_y: float
    var back_front_diff_x: float
    var back_front_diff_y: float
    
    var merge_count := 1
    while merge_count > 0:
        merge_count = 0
        count = surfaces.size()
        i = 0
        while i < count:
            surface1 = surfaces[i]
            surface1_front = surface1.front()
            surface1_back = surface1.back()
            
            j = i + 1
            while j < count:
                surface2 = surfaces[j]
                surface2_front = surface2.front()
                surface2_back = surface2.back()
                
                # Vector equality checks, allowing for some round-off error.
                front_back_diff_x = surface1_front.x - surface2_back.x
                front_back_diff_y = surface1_front.y - surface2_back.y
                back_front_diff_x = surface1_back.x - surface2_front.x
                back_front_diff_y = surface1_back.y - surface2_front.y
                if front_back_diff_x < Global.FLOAT_EPSILON and \
                        front_back_diff_x > -Global.FLOAT_EPSILON and \
                        front_back_diff_y < Global.FLOAT_EPSILON and \
                        front_back_diff_y > -Global.FLOAT_EPSILON:
                    # The start of surface 1 connects with the end of surface 2.
                    
                    # Merge the two surfaces, replacing the first surface and removing the second
                    # surface.
                    surface2.pop_back()
                    Global.concat(surface2, surface1)
                    surfaces.remove(j)
                    surfaces[i] = surface2
                    surface1 = surface2
                    surface1_front = surface1.front()
                    surface1_back = surface1.back()
                    
                    j -= 1
                    count -= 1
                    merge_count += 1
                elif back_front_diff_x < Global.FLOAT_EPSILON and \
                        back_front_diff_x > -Global.FLOAT_EPSILON and \
                        back_front_diff_y < Global.FLOAT_EPSILON and \
                        back_front_diff_y > -Global.FLOAT_EPSILON:
                    # The end of surface 1 connects with the start of surface 2.
                    
                    # Merge the two surfaces, replacing the first surface and removing the second
                    # surface.
                    surface1.pop_back()
                    Global.concat(surface1, surface2)
                    surfaces.remove(j)
                    
                    j -= 1
                    count -= 1
                    merge_count += 1
                
                j += 1
            
            i += 1

# Determine whether the points of the polygon are defined in a clockwise direction. This uses the
# shoelace formula.
func _is_polygon_clockwise(vertices: Array) -> bool:
    var vertex_count := vertices.size()
    var sum := 0.0
    var v1: Vector2 = vertices[vertex_count - 1]
    var v2: Vector2 = vertices[0]
    sum += (v2.x - v1.x) * (v2.y + v1.y)
    for i in range(vertex_count - 1):
        v1 = vertices[i]
        v2 = vertices[i + 1]
        sum += (v2.x - v1.x) * (v2.y + v1.y)
    return sum < 0
