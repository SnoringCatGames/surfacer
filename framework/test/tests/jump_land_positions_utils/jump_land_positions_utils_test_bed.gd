extends UnitTestBed
class_name JumpLandPositionsUtilsTestBed

# FIXME: ------------------------
# - Moves around 256px at max-speed v_0_x while ascending to -448px.

const CONNECTED_REGION_DEPTH := 64.0

const FLOOR_LENGTH_SHORT := 128.0
const FLOOR_LENGTH_LONG := 1024.0
const FLOOR_ORIGIN_Y_TOP := -448.0
const FLOOR_ORIGIN_Y_BOTTOM := 0.0
const FLOOR_ORIGIN_X_LEFT := -128.0
const FLOOR_ORIGIN_X_RIGHT := 128.0

var is_a_jump_calculator: bool

func before_each() -> void:
    set_up()
    is_a_jump_calculator = true

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
            connected_region_bounding_box = Rect2( \
                    first_end, \
                    Vector2( \
                            last_end.x, \
                            origin_y + CONNECTED_REGION_DEPTH))
            
        SurfaceSide.LEFT_WALL:
            # FIXME: -------------------
            pass
            
        SurfaceSide.RIGHT_WALL:
            # FIXME: -------------------
            pass
            
        SurfaceSide.CEILING:
            # FIXME: -------------------
            pass
            
        _:
            Utils.error()
    
    var vertices := [first_end, last_end]
    var tile_map_indices := []
    
    var surface := Surface.new( \
            vertices, \
            side, \
            tile_map_indices)
    surface.connected_region_bounding_box = connected_region_bounding_box
    
    return surface
