extends TestBed

###################################################################################################

class Test_check_instructions_for_collision:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_check_horizontal_step_for_collision:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME



class Test_update_vertical_end_state_for_time:
    extends TestBed

    var output_step: MovementCalcStep
    var vertical_step: MovementCalcStep
    
    func set_up(state := {}) -> void:
        output_step = MovementCalcStep.new()
        vertical_step = MovementCalcStep.new()

    # FIXME: LEFT OFF HERE --------A
    
    func test_TODO() -> void:
        pending()# FIXME
        # set_up({
        #     time_instruction_end = 0.0,
        #     position_start_y = 0.0,
        #     velocity_start_y = 0.0,
        # })
        # var time := 0.0
        # var is_step_end_time := true

        # PlayerMovement._upgrade_vertical_end_state_for_time(output_step, vertical_step, time, is_step_end_time)

        # assert_eq(output_step.position_step_end, Vector2(, ), END_POSITION_CLOSE_THRESHOLD)
        # assert_eq(output_step.velocity_step_end, Vector2(, ), END_POSITION_CLOSE_THRESHOLD)

class Test_calculate_end_time_for_jumping_to_position:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_time_to_release_acceleration:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_min_time_to_reach_position:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

###################################################################################################

class Test_get_nearby_and_fallable_surfaces:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_nearby_surfaces:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_are_surfaces_close:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_closest_fallable_surface:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_closest_fallable_surface_intersecting_triangle:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_closest_fallable_surface_intersecting_polygon:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

###################################################################################################

class Test_calculate_horizontal_step:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_vertical_step:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_convert_calculation_steps_to_player_instructions:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

###################################################################################################

class Test_get_max_horizontal_distance:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_get_max_upward_distance:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_test_calculate_jump_instructions:
    extends TestBed
    
    # FIXME: test the calculation of steps and conversion to instructions
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_test_get_all_edges_from_surface:
    extends TestBed
    
    # FIXME: test that the right number of edges are returned, and the edges have the right state
    
    func test_TODO() -> void:
        pending()# FIXME

###################################################################################################

# FIXME: Add more tests to calculate_steps_with_new_jump_height_test.gd

class Test_calculate_steps_from_constraint:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_steps_from_constraint_without_backtracking_on_height:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME

class Test_calculate_steps_from_constraint_with_backtracking_on_height:
    extends TestBed
    
    func test_TODO() -> void:
        pending()# FIXME
