extends "res://addons/gut/test.gd"

const TestBed := preload("res://framework/test/test_data/test_bed.gd")

const END_COORDINATE_CLOSE_THRESHOLD := 0.001
const END_POSITION_CLOSE_THRESHOLD := Vector2(0.001, 0.001)

class Base extends "res://addons/gut/test.gd":
    var test_bed: TestBed
    
    func before_each() -> void:
        test_bed = TestBed.new(self)
    
    func after_each() -> void:
        test_bed.destroy()
    
    func set_up(data: Dictionary) -> void:
        test_bed.set_up_level(data)






###################################################################################################

class Test_check_instructions_for_collision:
    extends Base
    
#    func before_each() -> void:
#        parent_before_each()
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_check_horizontal_step_for_collision:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_check_frame_for_collision:
    extends Base

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
            (start_tile_top_right_corner.x - start_tile_top_left_corner.x) / 2.0, \
            start_tile_top_left_corner.y)
    var start_tile_left_mid := Vector2(start_tile_top_left_corner.x, \
            start_tile_top_left_corner.y + \
            (start_tile_bottom_left_corner.y - start_tile_top_left_corner.y) / 2.0)
    
    var shape_query_params: Physics2DShapeQueryParameters
    var space_state: Physics2DDirectSpaceState
    var surface_parser: SurfaceParser
    var jump_from_platform_movement: JumpFromPlatformMovement

    func set_up(data: Dictionary) -> void:
        .set_up(data)
        space_state = test_bed.space_state
        shape_query_params = test_bed.global_calc_params.shape_query_params
        surface_parser = test_bed.surface_parser
    
    func set_frame_space_state(start_position: Vector2, displacement: Vector2) -> void:
        shape_query_params.transform = Transform2D(0.0, start_position)
        shape_query_params.motion = displacement
    
    func test_move_into_top_left_corner_from_left() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_top_left_corner + \
                Vector2(-half_player_width_height, 0) + \
                Vector2(-1, -1)
        var displacement := Vector2(half_player_width_height, 0)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.RIGHT_WALL)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_bottom_left_corner, start_tile_top_left_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_top_left_corner_from_above() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_top_left_corner + \
                Vector2(0, -half_player_width_height) + \
                Vector2(-1, -1)
        var displacement := Vector2(0, half_player_width_height)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.FLOOR)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_top_left_corner, start_tile_top_right_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_top_right_corner_from_right() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_top_right_corner + \
                Vector2(half_player_width_height, 0) + \
                Vector2(1, -1)
        var displacement := Vector2(-half_player_width_height, 0)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.LEFT_WALL)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_top_right_corner, start_tile_bottom_right_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_top_right_corner_from_above() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_top_right_corner + \
                Vector2(0, -half_player_width_height) + \
                Vector2(1, -1)
        var displacement := Vector2(0, half_player_width_height)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.FLOOR)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_top_left_corner, start_tile_top_right_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_bottom_left_corner_from_left() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_bottom_left_corner + \
                Vector2(-half_player_width_height, 0) + \
                Vector2(-1, 1)
        var displacement := Vector2(half_player_width_height, 0)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.RIGHT_WALL)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_bottom_left_corner, start_tile_top_left_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_bottom_left_corner_from_below() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_bottom_left_corner + \
                Vector2(0, half_player_width_height) + \
                Vector2(-1, 1)
        var displacement := Vector2(0, -half_player_width_height)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.CEILING)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_bottom_right_corner, start_tile_bottom_left_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_bottom_right_corner_from_right() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_bottom_right_corner + \
                Vector2(half_player_width_height, 0) + \
                Vector2(1, 1)
        var displacement := Vector2(-half_player_width_height, 0)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.LEFT_WALL)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_top_right_corner, start_tile_bottom_right_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_bottom_right_corner_from_below() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_bottom_right_corner + \
                Vector2(0, half_player_width_height) + \
                Vector2(1, 1)
        var displacement := Vector2(0, -half_player_width_height)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.CEILING)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_bottom_right_corner, start_tile_bottom_left_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_bottom_side_of_bottom_right_corner_from_mostly_right() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_bottom_right_corner + \
                Vector2(0, half_player_width_height) + \
                Vector2(1, 1)
        var displacement := Vector2(-half_player_width_height / 2.0, -3.0)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.CEILING)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_bottom_right_corner, start_tile_bottom_left_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_right_side_of_bottom_right_corner_from_mostly_below() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_bottom_right_corner + \
                Vector2(half_player_width_height, 0) + \
                Vector2(1, 1)
        var displacement := Vector2(-3.0, -half_player_width_height / 2.0)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.LEFT_WALL)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_top_right_corner, start_tile_bottom_right_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_left_mid_from_left() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_left_mid + \
                Vector2(-half_player_width_height, 0) + \
                Vector2(-1, 0)
        var displacement := Vector2(half_player_width_height, 0)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.RIGHT_WALL)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_bottom_left_corner, start_tile_top_left_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_top_mid_from_above() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_top_mid + \
                Vector2(0, -half_player_width_height) + \
                Vector2(0, -1)
        var displacement := Vector2(0, half_player_width_height)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.FLOOR)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_top_left_corner, start_tile_top_right_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_left_mid_from_left_with_tunnelling() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_left_mid + \
                Vector2(-half_player_width_height, 0) + \
                Vector2(-1, 0)
        var displacement := Vector2(tile_width + half_player_width_height * 3.0, 0)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.RIGHT_WALL)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_bottom_left_corner, start_tile_top_left_corner]))
        assert_eq(collision.position, Vector2(128, 73))
    
    func test_move_into_top_mid_from_above_with_tunnelling() -> void:
        set_up(test_bed.TEST_LEVEL_LONG_FALL)
        var start_position := \
                start_tile_top_mid + \
                Vector2(0, -half_player_width_height) + \
                Vector2(0, -1)
        var displacement := Vector2(0, tile_height + half_player_width_height * 3.0)
        set_frame_space_state(start_position, displacement)

        var collision := PlayerMovement.check_frame_for_collision( \
                space_state, shape_query_params, surface_parser)

        assert_not_null(collision)
        assert_eq(collision.surface.side, SurfaceSide.FLOOR)
        assert_eq(collision.surface.vertices, \
                PoolVector2Array([start_tile_top_left_corner, start_tile_top_right_corner]))
        assert_eq(collision.position, Vector2(128, 73))

class Test_calculate_constraints:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_update_vertical_end_state_for_time:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_end_time_for_jumping_to_position:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_time_to_release_acceleration:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_min_time_to_reach_position:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME









###################################################################################################

class Test_get_nearby_and_fallable_surfaces:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_nearby_surfaces:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_are_surfaces_close:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_closest_fallable_surface:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_closest_fallable_surface_intersecting_triangle:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_closest_fallable_surface_intersecting_polygon:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME











###################################################################################################

class Test_calculate_horizontal_step:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_vertical_step:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_convert_calculation_steps_to_player_instructions:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME







###################################################################################################

class Test_get_max_horizontal_distance:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_max_upward_distance:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_test_calculate_jump_instructions:
    extends Base
    
    # FIXME: test the calculation of steps and conversion to instructions
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_test_get_all_edges_from_surface:
    extends Base
    
    # FIXME: test that the right number of edges are returned, and the edges have the right state
    
    func test_TODO() -> void:
        pending()# FIXME







###################################################################################################

class Test_calculate_steps_with_new_jump_height:
    extends Base
    
    # FIXME: Test:
    # - out of reach
    # - long rise
    # - far distance
    # - as though this was called for higher-jump backtracking

    func test_long_fall_near_positions() -> void:
        var data := test_bed.TEST_LEVEL_LONG_FALL
        var start_position: Vector2 = data.start.positions.near
        var end_position: Vector2 = data.end.positions.near
        set_up(data)
        test_bed.global_calc_params.position_start = start_position
        test_bed.global_calc_params.position_end = end_position
        
        var results := test_bed.jump_from_platform_movement._calculate_steps_with_new_jump_height( \
                test_bed.global_calc_params, test_bed.global_calc_params.position_end, null)
        
        assert_not_null(results)
        assert_false(results.backtracked_for_new_jump_height)
        assert_eq(results.horizontal_steps.size(), 1)
        assert_almost_eq(results.vertical_step.time_step_end, 0.79757, Geometry.FLOAT_EPSILON) # FIXME: Actually hand-calculate what this time should be
        assert_almost_eq(results.vertical_step.position_step_end.y, end_position.y, END_COORDINATE_CLOSE_THRESHOLD)
        assert_almost_eq(results.horizontal_steps[0].position_step_end, end_position, END_POSITION_CLOSE_THRESHOLD)

    func test_long_fall_far_positions() -> void:
        var data := test_bed.TEST_LEVEL_LONG_FALL
        var start_position: Vector2 = data.start.positions.far
        var end_position: Vector2 = data.end.positions.far
        set_up(data)
        test_bed.global_calc_params.position_start = start_position
        test_bed.global_calc_params.position_end = end_position
        
        var results := test_bed.jump_from_platform_movement._calculate_steps_with_new_jump_height( \
                test_bed.global_calc_params, test_bed.global_calc_params.position_end, null)
        
        assert_not_null(results)
        assert_false(results.backtracked_for_new_jump_height)
        assert_eq(results.horizontal_steps.size(), 1)
        assert_almost_eq(results.vertical_step.time_step_end, 0.79757, Geometry.FLOAT_EPSILON) # FIXME: Actually hand-calculate what this time should be
        assert_almost_eq(results.vertical_step.position_step_end.y, end_position.y, END_COORDINATE_CLOSE_THRESHOLD)
        assert_almost_eq(results.horizontal_steps[0].position_step_end, end_position, END_POSITION_CLOSE_THRESHOLD)
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_steps_from_constraint:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_steps_from_constraint_without_backtracking_on_height:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_steps_from_constraint_with_backtracking_on_height:
    extends Base
    
    func test_TODO() -> void:
        pending()# FIXME
