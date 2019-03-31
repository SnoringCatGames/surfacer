extends Reference
class_name PlatformGraph

# TODO:
# - Update this list to use latest Trello notes
# - pre-parsing:
#   - parse_tilemap: parse TileMap to calculate platform nodes
#   - find_nearby_nodes: within radius or intersecting AABB
#   - node state:
#     - AABB
#     - reference to cells from TileMap
#     - collection of connecting edges / adjacent nodes
#   - edge state:
#     - movement type
#     - DON'T store instructions; dynamically calculate those when starting a given edge traversal
# - traversal:
#   - calculate current node for a given "state" (position, whether player is in-air, whether a wall-grab is active)
#   - implement modified A*:
#     - will need to also give weight to nodes, since we need to walk/climb within a node in order
#       to get to the position where we can start an edge traversal.
#   - Dynamically calculate instructions for the next edge when approaching a new edge traversal.
#   - 

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
    var tile_set := tile_map.tile_set
    var cell_size := tile_map.cell_size
    
    var used_cells = tile_map.get_used_cells()
    var used_cells_count = used_cells.size()
    
    var top_sides = Array()
    top_sides.resize(used_cells_count)
    
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
        _parse_sides(vertices_world_coords)

# This will parse each the given polygon into separate polylines corresponding to the top-side,
# left-side, and right-side of the shape. Each of these polylines will be stored with their
# vertices in clockwise order.
func _parse_sides(vertices: Array) -> void:
    var vertex_count := vertices.size()
    var is_clockwise = _is_polygon_clockwise(vertices)
    
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
    
    # FOR DEBUGGING
    print("************************************")
    print("vertices")
    print(vertices)
    print("is_clockwise")
    print(is_clockwise)
    print("top_side_start_index")
    print(top_side_start_index)
    print("top_side_end_index")
    print(top_side_end_index)
    print("right_side_end_index")
    print(right_side_end_index)
    print("left_side_start_index")
    print(left_side_start_index)
    print("top_side_vertices")
    print(top_side_vertices)
    print("right_side_vertices")
    print(right_side_vertices)
    print("left_side_vertices")
    print(left_side_vertices)

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
