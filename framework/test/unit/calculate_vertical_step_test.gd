extends TestBed

# Expected values were calculated using a Google spreadsheet:
# https://docs.google.com/spreadsheets/d/1qERIm_R-GjgmPqFgHa8GhI71gWRkXkX3Sy6FgSJNqrA/edit

func before_each() -> void:
    movement_params = MovementParams.new()
    movement_params.jump_boost = -1000.0
    movement_params.gravity_fast_fall = 5000.0
    movement_params.gravity_slow_ascent = 900.0
    movement_params.in_air_horizontal_acceleration = 1500
    movement_params.max_horizontal_speed_default = 400
    movement_params.max_upward_distance = \
            PlayerParams._calculate_max_upward_movement(movement_params)

func assert_vertical_step(step: MovementCalcStep, state: Dictionary) -> void:
    assert_not_null(step)
    assert_eq(step.time_start, 0.0)
    assert_almost_eq(step.time_instruction_end, state.time_instruction_end, \
            END_COORDINATE_CLOSE_THRESHOLD)
    assert_almost_eq(step.time_step_end, state.time_step_end, END_COORDINATE_CLOSE_THRESHOLD)
    assert_almost_eq(step.time_of_peak_height, state.time_of_peak_height, \
            END_COORDINATE_CLOSE_THRESHOLD)
    assert_eq(step.position_start, state.position_start)
    assert_almost_eq(step.velocity_start, Vector2(0, -1000.0), END_POSITION_CLOSE_THRESHOLD)
    assert_eq(step.horizontal_movement_sign, state.horizontal_movement_sign)

func test_duration_to_reach_upward_displacement() -> void:
    var position_start: Vector2 = TEST_LEVEL_LONG_RISE.start.positions.near
    var position_end: Vector2 = TEST_LEVEL_LONG_RISE.end.positions.near

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    var vertical_step := local_calc_params.vertical_step
    
    assert_vertical_step(vertical_step, {
        time_instruction_end = 0.7681523885,
        time_step_end = 0.8377213513,
        time_of_peak_height = 0.8298849585,
        position_start = position_start,
        horizontal_movement_sign = -1,
    })

func test_duration_to_reach_upward_displacement_less_than_jump_boost() -> void:
    var position_start: Vector2 = Vector2(0, 0)
    var position_end: Vector2 = Vector2(0, -32)

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    var vertical_step := local_calc_params.vertical_step
    
    assert_vertical_step(vertical_step, {
        time_instruction_end = 0.1151850147,
        time_step_end = 0.04340910831,
        time_of_peak_height = 0.294451712,
        position_start = position_start,
        horizontal_movement_sign = 0,
    })

func test_duration_to_reach_downward_displacement() -> void:
    var position_start: Vector2 = TEST_LEVEL_LONG_FALL.start.positions.near
    var position_end: Vector2 = TEST_LEVEL_LONG_FALL.end.positions.near

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    var vertical_step := local_calc_params.vertical_step

    assert_vertical_step(vertical_step, {
        time_instruction_end = 0.00759730371,
        time_step_end = 0.7975701278,
        time_of_peak_height = 0.206229789,
        position_start = position_start,
        horizontal_movement_sign = 1,
    })

func test_duration_to_reach_horizontal_displacement() -> void:
    var position_start: Vector2 = TEST_LEVEL_FAR_DISTANCE.start.positions.near
    var position_end: Vector2 = TEST_LEVEL_FAR_DISTANCE.end.positions.near

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    var vertical_step := local_calc_params.vertical_step

    assert_vertical_step(vertical_step, {
        time_instruction_end = 0.9218347844,
        time_step_end = 1.421666667,
        time_of_peak_height = 0.9559045232,
        position_start = position_start,
        horizontal_movement_sign = 1,
    })

func test_out_of_range_upward() -> void:
    var position_start: Vector2 = TEST_LEVEL_LONG_RISE.start.positions.near
    var position_end: Vector2 = TEST_LEVEL_LONG_RISE.end.positions.near + Vector2(0, -200)

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    
    assert_null(local_calc_params)

func test_out_of_range_horizontally() -> void:
    var position_start: Vector2 = TEST_LEVEL_FAR_DISTANCE.start.positions.far
    var position_end: Vector2 = TEST_LEVEL_FAR_DISTANCE.end.positions.far + Vector2(200, -100)

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    
    assert_null(local_calc_params)

func test_creates_local_calc_params() -> void:
    var position_start := Vector2(0.0, 0.0)
    var position_end := Vector2(100.0, -100.0)

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)

    assert_almost_eq(local_calc_params.position_start, position_start, \
            END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(local_calc_params.position_end, position_end, \
            END_POSITION_CLOSE_THRESHOLD)
