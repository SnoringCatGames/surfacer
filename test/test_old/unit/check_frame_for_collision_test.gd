extends IntegrationTestBed

var half_player_width_height := 10.0
var tile_width := 64.0
var tile_height := 64.0

var start_tile_top_left_corner := Vector2(128.0, 64.0)
var start_tile_top_right_corner := Vector2(192.0, 64.0)
var start_tile_bottom_left_corner := Vector2(128.0, 128.0)
var start_tile_bottom_right_corner := Vector2(192.0, 128.0)

var end_tile_top_left_corner := Vector2(256.0, 832.0)
var end_tile_top_right_corner := Vector2(320.0, 832.0)
var end_tile_bottom_left_corner := Vector2(256.0, 896.0)
var end_tile_bottom_right_corner := Vector2(320.0, 896.0)

var start_tile_top_mid := Vector2(start_tile_top_left_corner.x + \
        (start_tile_top_right_corner.x - start_tile_top_left_corner.x) / 2.0,
        start_tile_top_left_corner.y)
var start_tile_left_mid := Vector2(start_tile_top_left_corner.x,
        start_tile_top_left_corner.y + \
        (start_tile_bottom_left_corner.y - start_tile_top_left_corner.y) / 2.0)

var shape_query_params: Physics2DShapeQueryParameters

func set_up(data := TEST_LEVEL_LONG_FALL) -> void:
    .set_up(data)
    shape_query_params = edge_calc_params.shape_query_params

func set_frame_space_state(start_position: Vector2, displacement: Vector2) -> void:
    shape_query_params.transform = Transform2D(0.0, start_position)
    shape_query_params.motion = displacement

func assert_collison_state(collision: SurfaceCollision, expected_state: Dictionary) -> void:
    assert_not_null(collision)
    assert_eq(collision.surface.side, expected_state.side)
    assert_eq(collision.surface.vertices,
            PoolVector2Array([expected_state.surface_start, expected_state.surface_end]))
    assert_almost_eq(collision.position, expected_state.point_of_intersection,
            END_POSITION_CLOSE_THRESHOLD)

func test_move_into_top_left_corner_from_left() -> void:
    set_up()
    var start_position := \
            start_tile_top_left_corner + \
            Vector2(-half_player_width_height, 0) + \
            Vector2(-1, -1)
    var displacement := Vector2(half_player_width_height, 0)
    set_frame_space_state(start_position, displacement)
    
    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.RIGHT_WALL,
        surface_start = start_tile_bottom_left_corner,
        surface_end = start_tile_top_left_corner,
        point_of_intersection = start_tile_top_left_corner,
    })

func test_move_into_top_left_corner_from_above() -> void:
    set_up()
    var start_position := \
            start_tile_top_left_corner + \
            Vector2(0, -half_player_width_height) + \
            Vector2(-1, -1)
    var displacement := Vector2(0, half_player_width_height)
    set_frame_space_state(start_position, displacement)

    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.FLOOR,
        surface_start = start_tile_top_left_corner,
        surface_end = start_tile_top_right_corner,
        point_of_intersection = start_tile_top_left_corner,
    })

func test_move_into_top_right_corner_from_right() -> void:
    set_up()
    var start_position := \
            start_tile_top_right_corner + \
            Vector2(half_player_width_height, 0) + \
            Vector2(1, -1)
    var displacement := Vector2(-half_player_width_height, 0)
    set_frame_space_state(start_position, displacement)
    
    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.LEFT_WALL,
        surface_start = start_tile_top_right_corner,
        surface_end = start_tile_bottom_right_corner,
        point_of_intersection = start_tile_top_right_corner,
    })

func test_move_into_top_right_corner_from_above() -> void:
    set_up()
    var start_position := \
            start_tile_top_right_corner + \
            Vector2(0, -half_player_width_height) + \
            Vector2(1, -1)
    var displacement := Vector2(0, half_player_width_height)
    set_frame_space_state(start_position, displacement)

    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.FLOOR,
        surface_start = start_tile_top_left_corner,
        surface_end = start_tile_top_right_corner,
        point_of_intersection = start_tile_top_right_corner,
    })

func test_move_into_bottom_left_corner_from_left() -> void:
    set_up()
    var start_position := \
            start_tile_bottom_left_corner + \
            Vector2(-half_player_width_height, 0) + \
            Vector2(-1, 1)
    var displacement := Vector2(half_player_width_height, 0)
    set_frame_space_state(start_position, displacement)

    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.RIGHT_WALL,
        surface_start = start_tile_bottom_left_corner,
        surface_end = start_tile_top_left_corner,
        point_of_intersection = start_tile_bottom_left_corner,
    })

func test_move_into_bottom_left_corner_from_below() -> void:
    set_up()
    var start_position := \
            start_tile_bottom_left_corner + \
            Vector2(0, half_player_width_height) + \
            Vector2(-1, 1)
    var displacement := Vector2(0, -half_player_width_height)
    set_frame_space_state(start_position, displacement)

    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.CEILING,
        surface_start = start_tile_bottom_right_corner,
        surface_end = start_tile_bottom_left_corner,
        point_of_intersection = start_tile_bottom_left_corner,
    })

func test_move_into_bottom_right_corner_from_right() -> void:
    set_up()
    var start_position := \
            start_tile_bottom_right_corner + \
            Vector2(half_player_width_height, 0) + \
            Vector2(1, 1)
    var displacement := Vector2(-half_player_width_height, 0)
    set_frame_space_state(start_position, displacement)

    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.LEFT_WALL,
        surface_start = start_tile_top_right_corner,
        surface_end = start_tile_bottom_right_corner,
        point_of_intersection = start_tile_bottom_right_corner,
    })

func test_move_into_bottom_right_corner_from_below() -> void:
    set_up()
    var start_position := \
            start_tile_bottom_right_corner + \
            Vector2(0, half_player_width_height) + \
            Vector2(1, 1)
    var displacement := Vector2(0, -half_player_width_height)
    set_frame_space_state(start_position, displacement)

    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.CEILING,
        surface_start = start_tile_bottom_right_corner,
        surface_end = start_tile_bottom_left_corner,
        point_of_intersection = start_tile_bottom_right_corner,
    })

func test_move_into_bottom_side_of_bottom_right_corner_from_mostly_right() -> void:
    set_up()
    var start_position := \
            start_tile_bottom_right_corner + \
            Vector2(0, half_player_width_height) + \
            Vector2(1, 1)
    var displacement := Vector2(-half_player_width_height / 2.0, -3.0)
    set_frame_space_state(start_position, displacement)

    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.CEILING,
        surface_start = start_tile_bottom_right_corner,
        surface_end = start_tile_bottom_left_corner,
        point_of_intersection = start_tile_bottom_right_corner,
    })

func test_move_into_right_side_of_bottom_right_corner_from_mostly_below() -> void:
    set_up()
    var start_position := \
            start_tile_bottom_right_corner + \
            Vector2(half_player_width_height, 0) + \
            Vector2(1, 1)
    var displacement := Vector2(-3.0, -half_player_width_height / 2.0)
    set_frame_space_state(start_position, displacement)

    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.LEFT_WALL,
        surface_start = start_tile_top_right_corner,
        surface_end = start_tile_bottom_right_corner,
        point_of_intersection = start_tile_bottom_right_corner,
    })

func test_move_into_left_mid_from_left() -> void:
    set_up()
    var start_position := \
            start_tile_left_mid + \
            Vector2(-half_player_width_height, 0) + \
            Vector2(-1, 0)
    var displacement := Vector2(half_player_width_height, 0)
    set_frame_space_state(start_position, displacement)

    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.RIGHT_WALL,
        surface_start = start_tile_bottom_left_corner,
        surface_end = start_tile_top_left_corner,
        point_of_intersection = Vector2(128, 106),
    })

func test_move_into_top_mid_from_above() -> void:
    set_up()
    var start_position := \
            start_tile_top_mid + \
            Vector2(0, -half_player_width_height) + \
            Vector2(0, -1)
    var displacement := Vector2(0, half_player_width_height)
    set_frame_space_state(start_position, displacement)

    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.FLOOR,
        surface_start = start_tile_top_left_corner,
        surface_end = start_tile_top_right_corner,
        point_of_intersection = Vector2(150, 64),
    })

func test_move_into_left_mid_from_left_with_tunnelling() -> void:
    set_up()
    var start_position := \
            start_tile_left_mid + \
            Vector2(-half_player_width_height, 0) + \
            Vector2(-1, 0)
    var displacement := Vector2(tile_width + half_player_width_height * 3.0, 0)
    set_frame_space_state(start_position, displacement)
    
    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.RIGHT_WALL,
        surface_start = start_tile_bottom_left_corner,
        surface_end = start_tile_top_left_corner,
        point_of_intersection = Vector2(128, 82),
    })

func test_move_into_top_mid_from_above_with_tunnelling() -> void:
    set_up()
    var start_position := \
            start_tile_top_mid + \
            Vector2(0, -half_player_width_height) + \
            Vector2(0, -1)
    var displacement := Vector2(0, tile_height + half_player_width_height * 3.0)
    set_frame_space_state(start_position, displacement)
    
    var collision := FrameCollisionCheck.check_frame_for_collision(
            space_state, shape_query_params, surface_parser)
    
    assert_collison_state(collision, {
        side = SurfaceSide.FLOOR,
        surface_start = start_tile_top_left_corner,
        surface_end = start_tile_top_right_corner,
        point_of_intersection = Vector2(174, 64),
    })
