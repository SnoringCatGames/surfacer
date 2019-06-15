extends "res://addons/gut/test.gd"

const TestBed := preload("res://framework/test/test_data/test_bed.gd")

const END_COORDINATE_CLOSE_THRESHOLD := 0.001
const END_POSITION_CLOSE_THRESHOLD := Vector2(0.001, 0.001)

class Base extends "res://addons/gut/test.gd":
    var test_bed: TestBed
    var surface: Surface
    
    func before_each() -> void:
        test_bed = TestBed.new(self)
    
    func after_each() -> void:
        test_bed.destroy()
    
    func set_up(data: Dictionary) -> void:
        test_bed.set_up_level(data)
        
        surface = data.start.surface
        
        test_bed.global_calc_params.destination_surface = data.end.surface







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
    
    func test_TODO() -> void:
        pending()# FIXME

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
