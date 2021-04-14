extends IntegrationTestBed

# FIXME: Test:
# - out of reach
# - long rise
# - far distance
# - as though this was called for higher-jump backtracking

func test_long_fall_near_positions() -> void:
    var data := TEST_LEVEL_LONG_FALL
    var start_position: Vector2 = data.start.positions.near
    var end_position: Vector2 = data.end.positions.near
    set_up(data)
    edge_calc_params.position_start = start_position
    edge_calc_params.position_end = end_position
    
    var results := jump_from_platform_movement._calculate_steps_with_new_jump_height(
            edge_calc_params, edge_calc_params.position_end, null)
    
    assert_not_null(results)
    assert_false(results.backtracked_for_new_jump_height)
    assert_eq(results.horizontal_steps.size(), 1)
    assert_almost_eq(results.vertical_step.time_step_end, 0.79757, Gs.geometry.FLOAT_EPSILON) # FIXME: Actually hand-calculate what this time should be
    assert_almost_eq(results.vertical_step.position_step_end.y, end_position.y, END_COORDINATE_CLOSE_THRESHOLD)
    assert_almost_eq(results.horizontal_steps[0].position_step_end, end_position, END_POSITION_CLOSE_THRESHOLD)

func test_long_fall_far_positions() -> void:
    var data := TEST_LEVEL_LONG_FALL
    var start_position: Vector2 = data.start.positions.far
    var end_position: Vector2 = data.end.positions.far
    set_up(data)
    edge_calc_params.position_start = start_position
    edge_calc_params.position_end = end_position
    
    var results := jump_from_platform_movement._calculate_steps_with_new_jump_height(
            edge_calc_params, edge_calc_params.position_end, null)
    
    assert_not_null(results)
    assert_false(results.backtracked_for_new_jump_height)
    assert_eq(results.horizontal_steps.size(), 1)
    assert_almost_eq(results.vertical_step.time_step_end, 0.79757, Gs.geometry.FLOAT_EPSILON) # FIXME: Actually hand-calculate what this time should be
    assert_almost_eq(results.vertical_step.position_step_end.y, end_position.y, END_COORDINATE_CLOSE_THRESHOLD)
    assert_almost_eq(results.horizontal_steps[0].position_step_end, end_position, END_POSITION_CLOSE_THRESHOLD)

func test_TODO() -> void:
    pending()# FIXME
