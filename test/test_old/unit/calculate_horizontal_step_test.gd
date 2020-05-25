extends IntegrationTestBed

# Expected values were calculated using a Google spreadsheet:
# https://docs.google.com/spreadsheets/d/1qERIm_R-GjgmPqFgHa8GhI71gWRkXkX3Sy6FgSJNqrA/edit

var step_calc_params: EdgeStepCalcParams

func set_up(state := {}) -> void:
    movement_params = MovementParams.new()
    movement_params.in_air_horizontal_acceleration = 1500.0
    movement_params.jump_boost = -1000.0
    movement_params.gravity_slow_rise = 900.0
    movement_params.gravity_fast_fall = 5000.0
    movement_params.collider_shape = RectangleShape2D.new()

    var destination_surface := Surface.new([Vector2.INF], SurfaceSide.FLOOR, [INF])

    edge_calc_params = EdgeCalcParams.new(movement_params, null, null)
    edge_calc_params.movement_params = movement_params
    edge_calc_params.destination_surface = destination_surface

    var upcoming_constraint := MovementConstraint.new(destination_surface, Vector2.INF, true, true)

    var previous_step: EdgeStep
    if state.includes_previous_step:
        previous_step = EdgeStep.new()
        previous_step.time_step_end = state.time_start
        previous_step.position_step_end = state.position_start
        previous_step.velocity_step_end = state.velocity_start
    else:
        previous_step = null
    
    var vertical_step := EdgeStep.new()
    vertical_step.time_start = state.time_start
    vertical_step.position_start = state.position_start
    vertical_step.velocity_start = state.velocity_start
    vertical_step.time_step_end = state.vertical_time_step_end
    vertical_step.time_instruction_end = state.time_jump_instruction_end
    vertical_step.position_instruction_end = Vector2(INF, state.position_jump_instruction_end_y)
    vertical_step.velocity_instruction_end = Vector2(INF, state.velocity_jump_instruction_end_y)
    
    var position_start := Vector2.INF
    step_calc_params = EdgeStepCalcParams.new(position_start, state.position_end, \
            previous_step, vertical_step, upcoming_constraint)

func assert_horizontal_step(step: EdgeStep, state: Dictionary) -> void:
    assert_almost_eq(step.time_start, state.time_start, Geometry.FLOAT_EPSILON)
    assert_almost_eq(step.time_instruction_end, state.time_instruction_end, Geometry.FLOAT_EPSILON)
    assert_almost_eq(step.time_step_end, state.time_step_end, Geometry.FLOAT_EPSILON)
    assert_almost_eq(step.position_start, state.position_start, END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(step.position_step_end, state.position_step_end, END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(step.velocity_start.y, state.velocity_start_y, Geometry.FLOAT_EPSILON)
    assert_almost_eq(step.horizontal_movement_sign, state.horizontal_movement_sign, \
            Geometry.FLOAT_EPSILON)

func test_with_no_previous_or_next_steps() -> void:
    # start and end time are same as vertical step
    set_up({
        includes_previous_step = false,
        time_start = 0.0,
        position_start = Vector2(0.0, 0.0),
        velocity_start = Vector2(0.0, -1000.0),
        vertical_time_step_end = 1.533,
        # Distance between near points in far-distance level.
        position_end = Vector2(556.666961, 0.0),
        vertical_step_position_start_y = 0.0,
        time_jump_instruction_end = 1.066,
        position_jump_instruction_end_y = -562.745414,
        velocity_jump_instruction_end_y = -55,
    })

    var step := JumpFromSurfaceToSurfaceCalculator.calculate_horizontal_step( \
            step_calc_params, edge_calc_params)
    
    assert_horizontal_step(step, {
        time_start = 0.0,
        time_instruction_end = 0.261164,
        time_step_end = 1.551573,
        position_start = Vector2(0.0, 0.0),
        position_step_end = Vector2(556.666961, 0.0),
        velocity_start_y = -1000,
        horizontal_movement_sign = 1,
    })

func test_with_previous_step() -> void:
    pending() # TODO

func test_with_next_step_moving_left() -> void:
    pending() # TODO

func test_cant_reach_destination() -> void:
    pending() # TODO
