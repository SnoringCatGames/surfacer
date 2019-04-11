extends Node
class_name Utils

const UP := Vector2.UP
const DOWN := Vector2.DOWN
const LEFT := Vector2.LEFT
const RIGHT := Vector2.RIGHT
const FLOOR_MAX_ANGLE := PI / 4.0
const GRAVITY := 5000.0
const FLOAT_EPSILON := 0.00001

const SURFACE_DEPTH := 8.0
const SURFACE_DEPTH_DIVISIONS_COUNT := 8
const SURFACE_ALPHA_START := .8
const SURFACE_ALPHA_END := .1

const DEPTH_DIVISION_SIZE := SURFACE_DEPTH / SURFACE_DEPTH_DIVISIONS_COUNT

static func error(message: String) -> void:
    print("ERROR: %s" % message)
    assert(true)

# TODO: Replace this with any built-in feature whenever it exists
#       (https://github.com/godotengine/godot/issues/4715).
static func subarray(array: Array, start: int, length: int) -> Array:
    var result = range(length)
    for i in result:
        result[i] = array[start + i]
    return result

# TODO: Replace this with any built-in feature whenever it exists
#       (https://github.com/godotengine/godot/issues/4715).
static func concat(result: Array, other: Array) -> void:
    var old_result_size = result.size()
    var other_size = other.size()
    
    result.resize(old_result_size + other_size)
    
    for i in range(other_size):
        result[old_result_size + i] = other[i]

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

static func draw_dashed_line(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color, \
        dash_length: float, dash_gap: float, dash_offset: float = 0.0, \
        width: float = 1.0, antialiased: bool = false) -> void:
    var segment_length := from.distance_to(to)
    var direction_normalized: Vector2 = (to - from).normalized()
    
    var current_length := dash_offset
    var current_dash_length: float
    var current_from: Vector2
    var current_to: Vector2
    
    while current_length < segment_length:
        current_dash_length = dash_length if current_length + dash_length <= segment_length \
                else segment_length - current_length
        
        current_from = from + direction_normalized * current_length
        current_to = from + direction_normalized * (current_length + current_dash_length)
        
        canvas.draw_line(current_from, current_to, color, width, antialiased)
        
        current_length += dash_length + dash_gap

# TODO: Update this to honor gaps across vertices.
static func draw_dashed_polyline(canvas: CanvasItem, vertices: PoolVector2Array, color: Color, \
        dash_length: float, dash_gap: float, dash_offset: float = 0.0, \
        width: float = 1.0, antialiased: bool = false) -> void:
    var from: Vector2
    var to: Vector2
    for i in range(vertices.size() - 1):
        from = vertices[i]
        to = vertices[i + 1]
        draw_dashed_line(canvas, from, to, color, dash_length, dash_gap, dash_offset, width, \
                antialiased)

static func draw_surface(canvas: CanvasItem, surface: PoolVector2Array, normal: Vector2) -> void:
    var surface_depth_division_offset = normal * -DEPTH_DIVISION_SIZE
    var color := Color.from_hsv(randf(), 0.8, 0.8, 1)
    
    var polyline: PoolVector2Array
    var translation: Vector2
    var progress: float
    
    # "Surfaces" can single vertices in the degenerate case.
    if surface.size() > 1:
        for i in range(SURFACE_DEPTH_DIVISIONS_COUNT):
            translation = surface_depth_division_offset * i
            polyline = translate_polyline(surface, translation)
            progress = i / (SURFACE_DEPTH_DIVISIONS_COUNT - 1.0)
            color.a = SURFACE_ALPHA_START + progress * (SURFACE_ALPHA_END - SURFACE_ALPHA_START)
            canvas.draw_polyline(polyline, color, DEPTH_DIVISION_SIZE)
#            Utils.draw_dashed_polyline(self, polyline, color, 4.0, 3.0, 0.0, 2.0, false)
    else:
        color.a = 0.6
        canvas.draw_circle(surface[0], 8.0, color)

static func translate_polyline(vertices: PoolVector2Array, translation: Vector2) \
        -> PoolVector2Array:
    var result := PoolVector2Array()
    result.resize(vertices.size())
    for i in range(vertices.size()):
        result[i] = vertices[i] + translation
    return result

static func get_children_by_type(parent: Node, type) -> Array:
    var result = []
    for child in parent.get_children():
        if child is type:
            result.push_back(child)
    return result

static func get_which_wall_collided(body: KinematicBody2D) -> String:
    if body.is_on_wall():
        for i in range(body.get_slide_count()):
            var collision := body.get_slide_collision(i)
            if collision.normal.x > 0:
                return "left"
            elif collision.normal.x < 0:
                return "right"
    return "none"

static func get_floor_friction_coefficient(body: KinematicBody2D) -> float:
    var collision := _get_floor_collision(body)
    # Collision friction is a property of the TileMap node.
    if collision != null and collision.collider.collision_friction != null:
        return collision.collider.collision_friction
    return 0.0

static func _get_floor_collision(body: KinematicBody2D) -> KinematicCollision2D:
    if body.is_on_floor():
        for i in range(body.get_slide_count()):
            var collision := body.get_slide_collision(i)
            if abs(collision.normal.angle_to(UP)) <= FLOOR_MAX_ANGLE:
                return collision
    return null

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

static func _get_collision_tile_map_coord(position_world_coord: Vector2, tile_map: TileMap, \
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
                error("Invalid state: Problem calculating colliding cell on floor")
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
                error("Invalid state: Problem calculating colliding cell on ceiling")
        elif is_touching_left_wall:
            if is_there_a_tile_at_top_left:
                tile_coord = Vector2(top_left_cell_coord.x, top_left_cell_coord.y)
            elif is_there_a_tile_at_bottom_left:
                tile_coord = Vector2(top_left_cell_coord.x, top_left_cell_coord.y + 1)
            else:
                error("Invalid state: Problem calculating colliding cell on left wall")
        elif is_touching_right_wall:
            if is_there_a_tile_at_top_right:
                tile_coord = Vector2(top_left_cell_coord.x + 1, top_left_cell_coord.y)
            elif is_there_a_tile_at_bottom_right:
                tile_coord = Vector2(top_left_cell_coord.x + 1, top_left_cell_coord.y + 1)
            else:
                error("Invalid state: Problem calculating colliding cell on right wall")
        else:
            error("Invalid state: Problem calculating colliding cell")
        
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
                error("Invalid state: Problem calculating colliding cell on left wall")
        elif is_touching_right_wall:
            if is_there_a_tile_at_right:
                tile_coord = Vector2(left_cell_coord.x + 1, left_cell_coord.y)
            else:
                error("Invalid state: Problem calculating colliding cell on right wall")
        elif is_there_a_tile_at_left:
            tile_coord = Vector2(left_cell_coord.x, left_cell_coord.y)
        elif is_there_a_tile_at_right:
            tile_coord = Vector2(left_cell_coord.x + 1, left_cell_coord.y)
        else:
            error("Invalid state: Problem calculating colliding cell")
        
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
                error("Invalid state: Problem calculating colliding cell on floor")
        elif is_touching_ceiling:
            if is_there_a_tile_at_top:
                tile_coord = Vector2(top_cell_coord.x, top_cell_coord.y)
            else:
                error("Invalid state: Problem calculating colliding cell on ceiling")
        elif is_there_a_tile_at_bottom:
            tile_coord = Vector2(top_cell_coord.x, top_cell_coord.y + 1)
        elif is_there_a_tile_at_top:
            tile_coord = Vector2(top_cell_coord.x, top_cell_coord.y)
        else:
            error("Invalid state: Problem calculating colliding cell")
        
    else:
        tile_coord = world_to_tile_map(position_world_coord, tile_map)
    
    # Ensure the cell we calculated actually contains content.
    assert(tile_map.get_cellv(tile_coord) >= 0)
    
    return tile_coord
