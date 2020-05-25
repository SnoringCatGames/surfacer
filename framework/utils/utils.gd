extends Node

# In seconds.
const PHYSICS_TIME_STEP := 1 / 60.0

const IN_DEV_MODE := true

const GROUP_NAME_HUMAN_PLAYERS := "human_players"
const GROUP_NAME_COMPUTER_PLAYERS := "computer_players"
const GROUP_NAME_SURFACES := "surfaces"

static func error( \
        message := "An error occurred", \
        should_assert := true):
    print("ERROR: %s" % message)
    if should_assert:
        assert(false)

# TODO: Replace this with any built-in feature whenever it exists
#       (https://github.com/godotengine/godot/issues/4715).
static func subarray( \
        array: Array, \
        start: int, \
        length: int) -> Array:
    var result = range(length)
    for i in result:
        result[i] = array[start + i]
    return result

# TODO: Replace this with any built-in feature whenever it exists
#       (https://github.com/godotengine/godot/issues/4715).
static func concat( \
        result: Array, \
        other: Array) -> void:
    var old_result_size = result.size()
    var other_size = other.size()
    
    result.resize(old_result_size + other_size)
    
    for i in range(other_size):
        result[old_result_size + i] = other[i]

static func array_to_set(array: Array) -> Dictionary:
    var set := {}
    for element in array:
        set[element] = element
    return set

static func translate_polyline( \
        vertices: PoolVector2Array, \
        translation: Vector2) \
        -> PoolVector2Array:
    var result := PoolVector2Array()
    result.resize(vertices.size())
    for i in range(vertices.size()):
        result[i] = vertices[i] + translation
    return result

static func get_children_by_type( \
        parent: Node, \
        type) -> Array:
    var result = []
    for child in parent.get_children():
        if child is type:
            result.push_back(child)
    return result

static func get_which_wall_collided(body: KinematicBody2D) -> int:
    if body.is_on_wall():
        for i in range(body.get_slide_count()):
            var collision := body.get_slide_collision(i)
            if collision.normal.x > 0:
                return SurfaceSide.LEFT_WALL
            elif collision.normal.x < 0:
                return SurfaceSide.RIGHT_WALL
    return SurfaceSide.NONE

static func get_floor_friction_multiplier(body: KinematicBody2D) -> float:
    var collision := _get_floor_collision(body)
    # Collision friction is a property of the TileMap node.
    if collision != null and collision.collider.collision_friction != null:
        return collision.collider.collision_friction
    return 0.0

static func _get_floor_collision( \
        body: KinematicBody2D) -> KinematicCollision2D:
    if body.is_on_floor():
        for i in range(body.get_slide_count()):
            var collision := body.get_slide_collision(i)
            if abs(collision.normal.angle_to(Geometry.UP)) <= \
                    Geometry.FLOOR_MAX_ANGLE:
                return collision
    return null

static func add_scene( \
        parent: Node, \
        resource_path: String, \
        is_visible := true) -> Node:
    var scene := load(resource_path)
    var node: Node = scene.instance()
    node.visible = is_visible
    parent.add_child(node)
    return node

static func get_global_touch_position( \
        input_event: InputEvent, \
        global) -> Vector2:    
    return global.current_level.make_input_local(input_event).position
