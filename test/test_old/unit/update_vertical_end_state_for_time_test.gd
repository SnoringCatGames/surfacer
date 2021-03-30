extends IntegrationTestBed

# Expected values were calculated using a Google spreadsheet:
# https://docs.google.com/spreadsheets/d/1qERIm_R-GjgmPqFgHa8GhI71gWRkXkX3Sy6FgSJNqrA/edit

var output_step: EdgeStep
var vertical_step: VerticalEdgeStep

func set_up(state := {}) -> void:
    output_step = EdgeStep.new()
    output_step.position_step_end = Vector2.INF
    output_step.velocity_step_end = Vector2.INF
    output_step.position_instruction_end = Vector2.INF
    output_step.velocity_instruction_end = Vector2.INF
    
    movement_params = MovementParams.new()
    movement_params.gravity_fast_fall = 5000.0
    movement_params.gravity_slow_rise = 900.0
    
    vertical_step = EdgeStep.new()
    vertical_step.time_instruction_end = state.time_instruction_end
    vertical_step.position_start = Vector2(INF, state.position_start_y)
    vertical_step.velocity_start = Vector2(INF, state.velocity_start_y)

func test_updates_step_end_for_time_after_jump_instruction_end() -> void:
    set_up({
        time_instruction_end = 1.1,
        position_start_y = 0.0,
        velocity_start_y = -1000.0,
    })
    var time := 2.0
    var is_step_end_time := true

    Movement.calculate_vertical_state_for_time( \
            output_step, movement_params, vertical_step, time, is_step_end_time)

    assert_almost_eq(output_step.position_step_end, Vector2(INF, 1460.5), \
            END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(output_step.velocity_step_end, Vector2(INF, 4490.0), \
            END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(output_step.position_instruction_end, Vector2(INF, INF), \
            END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(output_step.velocity_instruction_end, Vector2(INF, INF), \
            END_POSITION_CLOSE_THRESHOLD)

func test_updates_instruction_end_for_time_after_jump_instruction_end() -> void:
    set_up({
        time_instruction_end = 1.1,
        position_start_y = 0.0,
        velocity_start_y = -1000.0,
    })
    var time := 2.0
    var is_step_end_time := false

    Movement.calculate_vertical_state_for_time( \
            output_step, movement_params, vertical_step, time, is_step_end_time)

    assert_almost_eq(output_step.position_step_end, Vector2(INF, INF), \
            END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(output_step.velocity_step_end, Vector2(INF, INF), \
            END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(output_step.position_instruction_end, Vector2(INF, 1460.5), \
            END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(output_step.velocity_instruction_end, Vector2(INF, 4490.0), \
            END_POSITION_CLOSE_THRESHOLD)

func test_time_before_jump_instruction_end() -> void:
    set_up({
        time_instruction_end = 1.1,
        position_start_y = 0.0,
        velocity_start_y = -1000.0,
    })
    var time := 0.5
    var is_step_end_time := true

    Movement.calculate_vertical_state_for_time( \
            output_step, movement_params, vertical_step, time, is_step_end_time)

    assert_almost_eq(output_step.position_step_end, Vector2(INF, -387.5), \
            END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(output_step.velocity_step_end, Vector2(INF, -550.0), \
            END_POSITION_CLOSE_THRESHOLD)
