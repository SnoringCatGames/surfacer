extends TestBed

# Expected values were calculated using a Google spreadsheet:
# https://docs.google.com/spreadsheets/d/1qERIm_R-GjgmPqFgHa8GhI71gWRkXkX3Sy6FgSJNqrA/edit

func before_each() -> void:
    movement_params = MovementParams.new()
    movement_params.jump_boost = -1000.0
    movement_params.gravity = 5000.0
    movement_params.ascent_gravity_multiplier = 0.18
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
    assert_almost_eq(step.position_step_end, state.position_step_end, \
            END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(step.velocity_start, Vector2(0, -1000.0), END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(step.velocity_step_end, state.velocity_step_end, \
            END_POSITION_CLOSE_THRESHOLD)
    assert_eq(step.horizontal_movement_sign, state.horizontal_movement_sign)

# FIXME: LEFT OFF HERE:
# - Use GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION? Or remove it...

func test_duration_to_reach_upward_displacement() -> void:
    pending()# FIXME
    var position_start: Vector2 = TEST_LEVEL_LONG_RISE.start.positions.near
    var position_end: Vector2 = TEST_LEVEL_LONG_RISE.end.positions.near

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    var vertical_step := local_calc_params.vertical_step
    
    assert_vertical_step(vertical_step, {
        time_instruction_end = INF,
        time_step_end = INF,
        time_of_peak_height = INF,
        position_start = Vector2(INF, INF),
        position_step_end = Vector2(INF, INF),
        velocity_step_end = Vector2(INF, INF),
        horizontal_movement_sign = INF,
    })

func test_duration_to_reach_upward_displacement_less_than_jump_boost() -> void:
    pending()# FIXME
    var position_start: Vector2 = Vector2(0, 0)
    var position_end: Vector2 = Vector2(0, -32)

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    var vertical_step := local_calc_params.vertical_step
    
    assert_vertical_step(vertical_step, {
        time_instruction_end = INF,
        time_step_end = INF,
        time_of_peak_height = INF,
        position_start = Vector2(INF, INF),
        position_step_end = Vector2(INF, INF),
        velocity_step_end = Vector2(INF, INF),
        horizontal_movement_sign = INF,
    })
    
func test_duration_to_reach_downward_displacement() -> void:
    pending()# FIXME
    var position_start: Vector2 = TEST_LEVEL_LONG_FALL.start.positions.near
    var position_end: Vector2 = TEST_LEVEL_LONG_FALL.end.positions.near

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    var vertical_step := local_calc_params.vertical_step
    
    assert_vertical_step(vertical_step, {
        time_instruction_end = INF,
        time_step_end = INF,
        time_of_peak_height = INF,
        position_start = Vector2(INF, INF),
        position_step_end = Vector2(INF, INF),
        velocity_step_end = Vector2(INF, INF),
        horizontal_movement_sign = INF,
    })

func test_duration_to_reach_horizontal_displacement() -> void:
    pending()# FIXME
    var position_start: Vector2 = TEST_LEVEL_FAR_DISTANCE.start.positions.near
    var position_end: Vector2 = TEST_LEVEL_FAR_DISTANCE.end.positions.near

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    var vertical_step := local_calc_params.vertical_step
    
    assert_vertical_step(vertical_step, {
        time_instruction_end = INF,
        time_step_end = INF,
        time_of_peak_height = INF,
        position_start = Vector2(INF, INF),
        position_step_end = Vector2(INF, INF),
        velocity_step_end = Vector2(INF, INF),
        horizontal_movement_sign = INF,
    })

func test_out_of_range_upward() -> void:
    var position_start: Vector2 = TEST_LEVEL_LONG_RISE.start.positions.near
    var position_end: Vector2 = TEST_LEVEL_LONG_RISE.end.positions.near + Vector2(0, -200)

    var local_calc_params := JumpFromPlatformMovement._calculate_vertical_step( \
            movement_params, position_start, position_end)
    
    assert_null(local_calc_params)

func test_out_of_range_horizontally() -> void:
    var position_start := TEST_LEVEL_FAR_DISTANCE.start.positions.far
    var position_end := TEST_LEVEL_FAR_DISTANCE.end.positions.far + Vector2(200, -100)

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
