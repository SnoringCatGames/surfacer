extends Node
class_name Utils

const UP := Vector2.UP
const DOWN := Vector2.DOWN
const LEFT := Vector2.LEFT
const RIGHT := Vector2.RIGHT
const FLOOR_MAX_ANGLE := PI / 4.0
const GRAVITY := 5000.0
const FLOAT_EPSILON := 0.00001

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

# Calculates the TileMap (grid-based) coordinates of the given position, relative to the origin of
# the TileMap's bounding box.
static func get_tile_map_index(position: Vector2, tile_map: TileMap) -> int:
    var used_rect := tile_map.get_used_rect()
    var tile_map_start := used_rect.position
    var tile_map_width: int = used_rect.size.x
    var tile_map_position: Vector2 = tile_map.world_to_map(position) - tile_map_start
    return (tile_map_position.y * tile_map_width + tile_map_position.x) as int
