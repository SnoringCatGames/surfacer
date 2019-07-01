extends TestBed

# Expected values were calculated using a Google spreadsheet:
# https://docs.google.com/spreadsheets/d/1qERIm_R-GjgmPqFgHa8GhI71gWRkXkX3Sy6FgSJNqrA/edit

var local_calc_params: MovementCalcLocalParams
var global_calc_params: MovementCalcGlobalParams

func set_up(state := {}) -> void:
    movement_params = MovementParams.new()
    movement_params.in_air_horizontal_acceleration = 1500.0
    movement_params.jump_boost = -1000.0
    movement_params.gravity_slow_ascent = 900.0
    movement_params.gravity_fast_fall = 5000.0

    var destination_surface := Surface.new([Vector2.INF], SurfaceSide.FLOOR)

    global_calc_params = MovementCalcGlobalParams.new()
    global_calc_params.movement_params = movement_params
    global_calc_params.destination_surface = destination_surface

    var upcoming_constraint := MovementConstraint.new()
    movement_constraint.surface = destination_surface

    var previous_step: MovementCalcStep
    if state.includes_previous_step:
        previous_step = MovementCalcStep.new()
        previous_step.time_step_end = state.time_start
        previous_step.position_step_end = state.position_start
        previous_step.velocity_step_end = state.velocity_start
    else:
        previous_step = null
    
    var vertical_step := MovementCalcStep.new()
    vertical_step.time_start = state.time_start
    vertical_step.position_start = state.position_start
    vertical_step.velocity_start = state.velocity_start
    vertical_step.time_step_end = state.vertical_time_step_end
    vertical_step.time_instruction_end = state.time_jump_instruction_end
    vertical_step.position_instruction_end = Vector2(INF, state.position_jump_instruction_end_y)
    vertical_step.velocity_instruction_end = Vector2(INF, state.velocity_jump_instruction_end_y)
    
    local_calc_params = MovementCalcLocalParams.new()
    local_calc_params.previous_step = previous_step
    local_calc_params.vertical_step = vertical_step
    local_calc_params.position_end = state.position_end

func assert_horizontal_step(step: MovementCalcStep, state: Dictionary) -> void:
    assert_almost_eq(step.time_start, state.time_start, Geometry.FLOAT_EPSILON)
    assert_almost_eq(step.time_instruction_end, state.time_instruction_end, Geometry.FLOAT_EPSILON)
    assert_almost_eq(step.time_step_end, state.time_step_end, Geometry.FLOAT_EPSILON)
    assert_almost_eq(step.position_start, state.position_start, END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(step.position_step_end, state.position_step_end, END_POSITION_CLOSE_THRESHOLD)
    assert_almost_eq(step.velocity_start.y, state.velocity_start_y, Geometry.FLOAT_EPSILON)
    assert_almost_eq(step.horizontal_movement_sign, state.horizontal_movement_sign, \
            Geometry.FLOAT_EPSILON)

# FIXME: LEFT OFF HERE: Test cases:
# - with no previous or next steps (start and end time are same as vertical step)
# - with previous step (start time != vertical-step start time)
# - with next step (end time != vertical-step end time)
# - moving leftward and rightward
# - Can't reach horizontal displacement in time

func test_no_previous_or_next_steps() -> void:
    pending() # FIXME
    set_up({
        time_start = 0.0,
        position_start = Vector2(0.0, 0.0),
        velocity_start = Vector2(0.0, -1000.0),
        vertical_time_step_end = 1.465,
        # Distance between near points in far-distance level.
        position_end = Vector2(512.0, 0.0),
        vertical_step_position_start_y = 0.0,
        time_jump_instruction_end = 0.966,
        position_jump_instruction_end_y = -538.916363,
        velocity_jump_instruction_end_y = -130,
    })

    var step := JumpFromPlatformMovement._calculate_horizontal_step( \
            local_calc_params, global_calc_params)
    
    assert_horizontal_step(result, {
        includes_previous_step = true,
        time_start = 0.0,
        time_instruction_end = ,
        time_step_end = 1.465,
        position_start = Vector2(0.0, 0.0),
        position_step_end = Vector2(512.0, 0.0),
        velocity_start_y = -1000,
        horizontal_movement_sign = 1,
    })
