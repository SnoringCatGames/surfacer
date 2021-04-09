class_name JumpLandPositionsUtilsTestBed
extends UnitTestBed

# NOTE: TestPlayer moves around 256px horizontally with max-speed start velocity while ascending
#       to -448px.

const CONNECTED_REGION_DEPTH := 64.0

const FLOOR_LENGTH_SHORT := 128.0
const FLOOR_LENGTH_LONG := 1024.0
const FLOOR_ORIGIN_Y_TOP := -448.0
const FLOOR_ORIGIN_Y_BOTTOM := 0.0
const FLOOR_ORIGIN_X_LEFT := -128.0
const FLOOR_ORIGIN_X_RIGHT := 128.0

const WALL_LENGTH_SHORT := 128.0
const WALL_LENGTH_LONG := 1024.0
const WALL_ORIGIN_Y_TOP := -448.0
const WALL_ORIGIN_Y_BOTTOM := 0.0
const WALL_ORIGIN_X_LEFT := -128.0
const WALL_ORIGIN_X_RIGHT := 128.0

var is_a_jump_calculator: bool

var half_width_min_offset: float
var half_width_max_offset: float
var vertical_offset_for_movement_around_wall_max: float

func before_each() -> void:
    set_up()
    is_a_jump_calculator = true
    half_width_min_offset = movement_params.collider_half_width_height.x + 0.01
    half_width_max_offset = movement_params.collider_half_width_height.x * 2.0
    vertical_offset_for_movement_around_wall_max = \
            movement_params.collider_half_width_height.y * 2.0

func create_surface(params: Dictionary) -> Surface:
    var side: int = params.side
    
    var first_end: Vector2
    var last_end: Vector2
    var connected_region_bounding_box: Rect2
    match side:
        SurfaceSide.FLOOR:
            var origin_y := \
                    FLOOR_ORIGIN_Y_TOP if \
                    params.is_top else \
                    FLOOR_ORIGIN_Y_BOTTOM
            var origin_x := \
                    FLOOR_ORIGIN_X_LEFT if \
                    params.is_left else \
                    FLOOR_ORIGIN_X_RIGHT
            var half_length := \
                    FLOOR_LENGTH_SHORT / 2.0 if \
                    params.is_short else \
                    FLOOR_LENGTH_LONG / 2.0
            
            first_end = Vector2( \
                    origin_x - half_length, \
                    origin_y)
            last_end = Vector2( \
                    origin_x + half_length, \
                    origin_y)
            var connected_region_position := first_end
            var connected_region_size := Vector2( \
                    half_length * 2.0, \
                    CONNECTED_REGION_DEPTH)
            connected_region_bounding_box = Rect2( \
                    connected_region_position, \
                    connected_region_size)
            
        SurfaceSide.LEFT_WALL:
            var origin_y := \
                    WALL_ORIGIN_Y_TOP if \
                    params.is_top else \
                    WALL_ORIGIN_Y_BOTTOM
            var origin_x := \
                    WALL_ORIGIN_X_LEFT if \
                    params.is_left else \
                    WALL_ORIGIN_X_RIGHT
            var half_length := \
                    WALL_LENGTH_SHORT / 2.0 if \
                    params.is_short else \
                    WALL_LENGTH_LONG / 2.0
            
            first_end = Vector2( \
                    origin_x, \
                    origin_y - half_length)
            last_end = Vector2( \
                    origin_x, \
                    origin_y + half_length)
            var connected_region_position := Vector2( \
                    first_end.x - CONNECTED_REGION_DEPTH, \
                    first_end.y)
            var connected_region_size := Vector2( \
                    CONNECTED_REGION_DEPTH, \
                    half_length * 2.0)
            connected_region_bounding_box = Rect2( \
                    connected_region_position, \
                    connected_region_size)
            
        SurfaceSide.RIGHT_WALL:
            var origin_y := \
                    WALL_ORIGIN_Y_TOP if \
                    params.is_top else \
                    WALL_ORIGIN_Y_BOTTOM
            var origin_x := \
                    WALL_ORIGIN_X_LEFT if \
                    params.is_left else \
                    WALL_ORIGIN_X_RIGHT
            var half_length := \
                    WALL_LENGTH_SHORT / 2.0 if \
                    params.is_short else \
                    WALL_LENGTH_LONG / 2.0
            
            first_end = Vector2( \
                    origin_x, \
                    origin_y + half_length)
            last_end = Vector2( \
                    origin_x, \
                    origin_y - half_length)
            var connected_region_position := last_end
            var connected_region_size := Vector2( \
                    CONNECTED_REGION_DEPTH, \
                    half_length * 2.0)
            connected_region_bounding_box = Rect2( \
                    connected_region_position, \
                    connected_region_size)
            
        SurfaceSide.CEILING:
            # TODO: Implement.
            Gs.logger.error()
            
        _:
            Gs.logger.error()
    
    var vertices := [first_end, last_end]
    var tile_map: SurfacesTileMap = null
    var tile_map_indices := []
    
    var surface := Surface.new( \
            vertices, \
            side, \
            tile_map, \
            tile_map_indices)
    surface.connected_region_bounding_box = connected_region_bounding_box
    
    return surface

static func translate_surface( \
        surface: Surface, \
        translation: Vector2) -> void:
    for i in surface.vertices.size():
        surface.vertices[i] += translation
    surface.bounding_box.position += translation
    surface.connected_region_bounding_box.position += translation
