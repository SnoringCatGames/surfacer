extends Node
class_name Geometry

const UP := Vector2.UP
const DOWN := Vector2.DOWN
const LEFT := Vector2.LEFT
const RIGHT := Vector2.RIGHT
const FLOOR_MAX_ANGLE := PI / 4.0
const GRAVITY := 5000.0
const FLOAT_EPSILON := 0.00001

# Calculates the minimum squared distance between a line segment and a point.
static func get_distance_squared_from_point_to_segment( \
        point: Vector2, segment_a: Vector2, segment_b: Vector2) -> float:
    var closest_point := get_closest_point_on_segment_to_point(point, segment_a, segment_b)
    return point.distance_squared_to(closest_point)

# Calculates the minimum squared distance between a polyline and a point.
static func get_distance_squared_from_point_to_polyline( \
        point: Vector2, polyline: PoolVector2Array) -> float:
    var closest_point := get_closest_point_on_polyline_to_point(point, polyline)
    return point.distance_squared_to(closest_point)

# Calculates the minimum squared distance between two NON-INTERSECTING line segments.
static func get_distance_squared_between_non_intersecting_segments( \
        segment_1_a: Vector2, segment_1_b: Vector2, \
        segment_2_a: Vector2, segment_2_b: Vector2) -> float:
    var closest_on_2_to_1_a = \
            get_closest_point_on_segment_to_point(segment_1_a, segment_2_a, segment_2_b)
    var closest_on_2_to_1_b = \
            get_closest_point_on_segment_to_point(segment_1_b, segment_2_a, segment_2_b)
    var closest_on_1_to_2_a = \
            get_closest_point_on_segment_to_point(segment_2_a, segment_1_a, segment_1_b)
    var closest_on_1_to_2_b = \
            get_closest_point_on_segment_to_point(segment_2_a, segment_1_a, segment_1_b)
    
    var distance_squared_from_2_to_1_a = closest_on_2_to_1_a.distance_squared_to(segment_1_a)
    var distance_squared_from_2_to_1_b = closest_on_2_to_1_b.distance_squared_to(segment_1_b)
    var distance_squared_from_1_to_2_a = closest_on_1_to_2_a.distance_squared_to(segment_2_a)
    var distance_squared_from_1_to_2_b = closest_on_1_to_2_b.distance_squared_to(segment_2_b)
    
    return min(min(distance_squared_from_2_to_1_a, distance_squared_from_2_to_1_b), \
            min(distance_squared_from_1_to_2_a, distance_squared_from_1_to_2_b))

# Calculates the closest position on a line segment to a point.
static func get_closest_point_on_segment_to_point( \
        point: Vector2, segment_a: Vector2, segment_b: Vector2) -> Vector2:
    var v = segment_b - segment_a
    var u = segment_a - point
    var t = - v.dot(u) / v.dot(v)
    
    if t >= 0 and t <= 1:
        # The projection of the point lies within the bounds of the segment.
        return (1 - t) * segment_a + t * segment_b
    else:
        # The projection of the point lies outside bounds of the segment.
        var distance_squared_a = point.distance_squared_to(segment_a)
        var distance_squared_b = point.distance_squared_to(segment_b)
        return segment_a if distance_squared_a < distance_squared_b else segment_b

# Calculates the minimum squared distance between a polyline and a point.
static func get_closest_point_on_polyline_to_point( \
        point: Vector2, polyline: PoolVector2Array) -> Vector2:
    if polyline.size() == 1:
        return polyline[0]
    
    var closest_point := get_closest_point_on_segment_to_point(point, polyline[0], polyline[1])
    var closest_distance_squared := point.distance_squared_to(closest_point)
    
    var current_closest_point: Vector2
    var current_distance_squared: float
    for i in range(1, polyline.size() - 1):
        current_closest_point = \
                get_closest_point_on_segment_to_point(point, polyline[i], polyline[i + 1])
        current_distance_squared = point.distance_squared_to(current_closest_point)
        if current_distance_squared < closest_distance_squared:
            closest_distance_squared = current_distance_squared
            closest_point = current_closest_point
    
    return closest_point

# Calculates the point of intersection between two line segments. If the segments don't intersect,
# this returns a Vector2 with values of INFINITY.
static func get_intersection_of_segments(segment_1_a: Vector2, segment_1_b: Vector2, \
        segment_2_a: Vector2, segment_2_b: Vector2) -> Vector2:
    var r = segment_1_b - segment_1_a
    var s = segment_2_b - segment_2_a
    
    var u_numerator = (segment_2_a - segment_1_a).cross(r)
    var denominator = r.cross(s)
    
    if u_numerator == 0 and denominator == 0:
        # The segments are collinear.
        var t0_numerator = (segment_2_a - segment_1_a) * r
        var t1_numerator = (segment_1_a - segment_2_a) * s
        if 0 <= t0_numerator and t0_numerator <= r * r or \
                0 <= t1_numerator and t1_numerator <= s * s:
            # The segments overlap. Return one of the segment endpoints that lies within the
            # overlap region.
            if (segment_1_a.x >= segment_2_a.x and segment_1_a.x <= segment_2_b.x) or \
                    (segment_1_a.x <= segment_2_a.x and segment_1_a.x >= segment_2_b.x):
                return segment_1_a
            else:
                return segment_1_b
        else:
            # The segments are disjoint.
            return Vector2.INF
    elif denominator == 0:
        # The segments are parallel.
        return Vector2.INF
    else:
        # The segments are not parallel.
        var u = u_numerator / denominator
        var t = (segment_2_a - segment_1_a).cross(s) / denominator
        if t >= 0 and t <= 1 and u >= 0 and u <= 1:
            # The segments intersect.
            return segment_1_a + t * r
        else:
            # The segments don't touch.
            return Vector2.INF

# Calculates the point of intersection between a line segment and a polyline. If the two don't
# intersect, this returns a Vector2 with values of INFINITY.
static func get_intersection_of_segment_and_polyline(segment_a: Vector2, segment_b: Vector2, \
        vertices: PoolVector2Array) -> Vector2:
    if vertices.size() == 1:
        if do_point_and_segment_intersect(segment_a, segment_b, vertices[0]):
            return vertices[0]
    else:
        var intersection: Vector2
        for i in range(vertices.size() - 1):
            intersection = get_intersection_of_segments(segment_a, segment_b, vertices[i], vertices[i + 1])
            if intersection != Vector2.INF:
                return intersection
    return Vector2.INF

static func are_points_equal_with_epsilon(a: Vector2, b: Vector2) -> bool:
    var x_diff = b.x - a.x
    var y_diff = b.y - a.y
    return -FLOAT_EPSILON < x_diff and x_diff < FLOAT_EPSILON and \
            -FLOAT_EPSILON < y_diff and y_diff < FLOAT_EPSILON

# Determine whether the points of the polygon are defined in a clockwise direction. This uses the
# shoelace formula.
static func is_polygon_clockwise(vertices: Array) -> bool:
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

static func are_points_collinear(p1: Vector2, p2: Vector2, p3: Vector2) -> bool:
    return abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)) < FLOAT_EPSILON

static func do_point_and_segment_intersect(point: Vector2, segment_a: Vector2, segment_b: Vector2) -> bool:
    return are_points_collinear(point, segment_a, segment_b) and \
            ((point.x <= segment_a.x and point.x >= segment_b.x) or \
            (point.x >= segment_a.x and point.x <= segment_b.x))

static func get_bounding_box_for_points(points: PoolVector2Array) -> Rect2:
    assert(points.size() > 0)
    var bounding_box = Rect2(points[0], Vector2.ZERO)
    for i in range(1, points.size()):
        bounding_box.expand(points[i])
    return bounding_box

static func distance_squared_from_point_to_rect(point: Vector2, rect: Rect2) -> float:
    var rect_min := rect.position
    var rect_max := rect.end
    
    if point.x < rect_min.x:
        if point.y < rect_min.y:
            return point.distance_squared_to(rect_min)
        elif point.y > rect_max.y:
            return point.distance_squared_to(Vector2(rect_min.x, rect_max.y))
        else:
            var distance = rect_min.x - point.x
            return distance * distance
    elif point.x > rect_max.x:
        if point.y < rect_min.y:
            return point.distance_squared_to(Vector2(rect_max.x, rect_min.y))
        elif point.y > rect_max.y:
            return point.distance_squared_to(rect_max)
        else:
            var distance = point.x - rect_max.x
            return distance * distance
    else:
        if point.y < rect_min.y:
            var distance = rect_min.y - point.y
            return distance * distance
        elif point.y > rect_max.y:
            var distance = point.y - rect_max.y
            return distance * distance
        else:
            return 0.0

# The build-in TileMap.world_to_map generates incorrect results around cell boundaries, so we use a
# custom utility.
static func world_to_tile_map(position: Vector2, tile_map: TileMap) -> Vector2:
    var cell_size_world_coord := tile_map.cell_size
    var position_map_coord := position / cell_size_world_coord
    position_map_coord = Vector2(floor(position_map_coord.x), floor(position_map_coord.y))
    return position_map_coord

# Calculates the TileMap (grid-based) coordinates of the given position, relative to the origin of
# the TileMap's bounding box.
static func get_tile_map_index_from_world_coord(position: Vector2, tile_map: TileMap, \
        side: String) -> int:
    var position_grid_coord = world_to_tile_map(position, tile_map)
    return get_tile_map_index_from_grid_coord(position_grid_coord, tile_map)

# Calculates the TileMap (grid-based) coordinates of the given position, relative to the origin of
# the TileMap's bounding box.
static func get_tile_map_index_from_grid_coord(position: Vector2, tile_map: TileMap) -> int:
    var used_rect := tile_map.get_used_rect()
    var tile_map_start := used_rect.position
    var tile_map_width: int = used_rect.size.x
    var tile_map_position: Vector2 = position - tile_map_start
    return (tile_map_position.y * tile_map_width + tile_map_position.x) as int

static func get_collision_tile_map_coord(position_world_coord: Vector2, tile_map: TileMap, \
        is_touching_floor: bool, is_touching_ceiling: bool, \
        is_touching_left_wall: bool, is_touching_right_wall: bool) -> Vector2:
    var half_cell_size = tile_map.cell_size / 2
    var used_rect = tile_map.get_used_rect()
    var position_relative_to_tile_map = \
            position_world_coord - used_rect.position * tile_map.cell_size
    
    var cell_width_mod = abs(fmod(position_relative_to_tile_map.x, tile_map.cell_size.x))
    var cell_height_mod = abs(fmod(position_relative_to_tile_map.y, tile_map.cell_size.y))
    
    var is_between_cells_horizontally = cell_width_mod < FLOAT_EPSILON or \
            tile_map.cell_size.x - cell_width_mod < FLOAT_EPSILON
    var is_between_cells_vertically = cell_height_mod < FLOAT_EPSILON or \
            tile_map.cell_size.y - cell_height_mod < FLOAT_EPSILON
    
    var tile_coord: Vector2
    
    if is_between_cells_horizontally and is_between_cells_vertically:
        var top_left_cell_coord = \
                world_to_tile_map(Vector2(position_world_coord.x - half_cell_size.x, \
                        position_world_coord.y - half_cell_size.y), tile_map)
        
        var is_there_a_tile_at_top_left = \
                tile_map.get_cellv(top_left_cell_coord) >= 0
        var is_there_a_tile_at_top_right = \
                tile_map.get_cell(top_left_cell_coord.x + 1, top_left_cell_coord.y) >= 0
        var is_there_a_tile_at_bottom_left = \
                tile_map.get_cell(top_left_cell_coord.x, top_left_cell_coord.y + 1) >= 0
        var is_there_a_tile_at_bottom_right = \
                tile_map.get_cell(top_left_cell_coord.x + 1, top_left_cell_coord.y + 1) >= 0
        
        if is_touching_floor:
            if is_touching_left_wall:
                assert(is_there_a_tile_at_bottom_left)
                tile_coord = Vector2(top_left_cell_coord.x, top_left_cell_coord.y + 1)
            if is_touching_right_wall:
                assert(is_there_a_tile_at_bottom_right)
                tile_coord = Vector2(top_left_cell_coord.x + 1, top_left_cell_coord.y + 1)
            elif is_there_a_tile_at_bottom_left:
                tile_coord = Vector2(top_left_cell_coord.x, top_left_cell_coord.y + 1)
            elif is_there_a_tile_at_bottom_right:
                tile_coord = Vector2(top_left_cell_coord.x + 1, top_left_cell_coord.y + 1)
            else:
                Utils.error("Invalid state: Problem calculating colliding cell on floor")
        elif is_touching_ceiling:
            if is_touching_left_wall:
                assert(is_there_a_tile_at_top_left)
                tile_coord = Vector2(top_left_cell_coord.x, top_left_cell_coord.y)
            if is_touching_right_wall:
                assert(is_there_a_tile_at_top_right)
                tile_coord = Vector2(top_left_cell_coord.x + 1, top_left_cell_coord.y)
            elif is_there_a_tile_at_top_left:
                tile_coord = Vector2(top_left_cell_coord.x, top_left_cell_coord.y)
            elif is_there_a_tile_at_top_right:
                tile_coord = Vector2(top_left_cell_coord.x + 1, top_left_cell_coord.y)
            else:
                Utils.error("Invalid state: Problem calculating colliding cell on ceiling")
        elif is_touching_left_wall:
            if is_there_a_tile_at_top_left:
                tile_coord = Vector2(top_left_cell_coord.x, top_left_cell_coord.y)
            elif is_there_a_tile_at_bottom_left:
                tile_coord = Vector2(top_left_cell_coord.x, top_left_cell_coord.y + 1)
            else:
                Utils.error("Invalid state: Problem calculating colliding cell on left wall")
        elif is_touching_right_wall:
            if is_there_a_tile_at_top_right:
                tile_coord = Vector2(top_left_cell_coord.x + 1, top_left_cell_coord.y)
            elif is_there_a_tile_at_bottom_right:
                tile_coord = Vector2(top_left_cell_coord.x + 1, top_left_cell_coord.y + 1)
            else:
                Utils.error("Invalid state: Problem calculating colliding cell on right wall")
        else:
            Utils.error("Invalid state: Problem calculating colliding cell")
        
    elif is_between_cells_horizontally:
        var left_cell_coord = \
                world_to_tile_map(Vector2(position_world_coord.x - half_cell_size.x, \
                        position_world_coord.y), tile_map)
        var is_there_a_tile_at_left = tile_map.get_cellv(left_cell_coord) >= 0
        var is_there_a_tile_at_right = \
                tile_map.get_cell(left_cell_coord.x + 1, left_cell_coord.y) >= 0
        
        if is_touching_left_wall:
            if is_there_a_tile_at_left:
                tile_coord = Vector2(left_cell_coord.x, left_cell_coord.y)
            else:
                Utils.error("Invalid state: Problem calculating colliding cell on left wall")
        elif is_touching_right_wall:
            if is_there_a_tile_at_right:
                tile_coord = Vector2(left_cell_coord.x + 1, left_cell_coord.y)
            else:
                Utils.error("Invalid state: Problem calculating colliding cell on right wall")
        elif is_there_a_tile_at_left:
            tile_coord = Vector2(left_cell_coord.x, left_cell_coord.y)
        elif is_there_a_tile_at_right:
            tile_coord = Vector2(left_cell_coord.x + 1, left_cell_coord.y)
        else:
            Utils.error("Invalid state: Problem calculating colliding cell")
        
    elif is_between_cells_vertically:
        var top_cell_coord = world_to_tile_map(Vector2(position_world_coord.x, \
                position_world_coord.y - half_cell_size.y), tile_map)
        var is_there_a_tile_at_bottom = \
                tile_map.get_cell(top_cell_coord.x, top_cell_coord.y + 1) >= 0
        var is_there_a_tile_at_top = tile_map.get_cellv(top_cell_coord) >= 0
        
        if is_touching_floor:
            if is_there_a_tile_at_bottom:
                tile_coord = Vector2(top_cell_coord.x, top_cell_coord.y + 1)
            else:
                Utils.error("Invalid state: Problem calculating colliding cell on floor")
        elif is_touching_ceiling:
            if is_there_a_tile_at_top:
                tile_coord = Vector2(top_cell_coord.x, top_cell_coord.y)
            else:
                Utils.error("Invalid state: Problem calculating colliding cell on ceiling")
        elif is_there_a_tile_at_bottom:
            tile_coord = Vector2(top_cell_coord.x, top_cell_coord.y + 1)
        elif is_there_a_tile_at_top:
            tile_coord = Vector2(top_cell_coord.x, top_cell_coord.y)
        else:
            Utils.error("Invalid state: Problem calculating colliding cell")
        
    else:
        tile_coord = world_to_tile_map(position_world_coord, tile_map)
    
    # Ensure the cell we calculated actually contains content.
    assert(tile_map.get_cellv(tile_coord) >= 0)
    
    return tile_coord
