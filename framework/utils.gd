extends Node
class_name Utils

const UP := Vector2.UP
const DOWN := Vector2.DOWN
const LEFT := Vector2.LEFT
const RIGHT := Vector2.RIGHT
const FLOOR_MAX_ANGLE := PI / 4
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
