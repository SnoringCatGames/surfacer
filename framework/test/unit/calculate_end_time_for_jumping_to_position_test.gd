extends TestBed

# Expected values were calculated using a Google spreadsheet:
# https://docs.google.com/spreadsheets/d/1qERIm_R-GjgmPqFgHa8GhI71gWRkXkX3Sy6FgSJNqrA/edit

var vertical_step: MovementCalcStep
var target_position: Vector2
var upcoming_constraint: MovementConstraint
var destination_surface: Surface

func set_up(state := {}) -> void:
    movement_params = MovementParams.new()
    movement_params.jump_boost = -1000.0
    movement_params.gravity_slow_ascent = 900.0
    movement_params.gravity_fast_fall = 5000.0

    vertical_step = MovementCalcStep.new()
    vertical_step.position_start = Vector2(INF, state.position_start_y)
    vertical_step.time_instruction_end = state.time_instruction_end
    vertical_step.position_instruction_end = Vector2(INF, state.position_instruction_end_y)
    vertical_step.velocity_instruction_end = Vector2(INF, state.velocity_instruction_end_y)
    
    target_position = Vector2(INF, state.target_position_y)
    
    var surface := Surface.new([Vector2.INF], state.surface_side, [INF])
    
    if state.should_use_constraint:
        upcoming_constraint = \
                MovementConstraint.new(surface, Vector2.INF, true, state.should_stay_on_min_side)
        upcoming_constraint.surface = surface
    else:
        upcoming_constraint = null
    
    destination_surface = surface

func test_floor_with_constraint() -> void:
    # is_position_before_peak = false
    # is_position_before_instruction_end = false
    set_up({
        target_position_y = -110.0,
        position_instruction_end_y = -100.0,
        surface_side = SurfaceSide.FLOOR,
        should_use_constraint = true,
        should_stay_on_min_side = true,
        position_start_y = 0.0,
        velocity_instruction_end_y = -500.0,
        time_instruction_end = 0.5,
    })
    var expected := 0.67745966692414833
    
    var actual := PlayerMovement._calculate_end_time_for_jumping_to_position(movement_params, \
            vertical_step, target_position, upcoming_constraint, destination_surface)

    assert_almost_eq(actual, expected, Geometry.FLOAT_EPSILON)

func test_floor_without_constraint() -> void:
    # is_position_before_peak = false
    # is_position_before_instruction_end = false
    set_up({
        target_position_y = -110.0,
        position_instruction_end_y = -100.0,
        surface_side = SurfaceSide.FLOOR,
        should_use_constraint = false,
        should_stay_on_min_side = true,
        position_start_y = 0.0,
        velocity_instruction_end_y = -500.0,
        time_instruction_end = 0.5,
    })
    var expected := 0.67745966692414833
    
    var actual := PlayerMovement._calculate_end_time_for_jumping_to_position(movement_params, \
            vertical_step, target_position, upcoming_constraint, destination_surface)

    assert_almost_eq(actual, expected, Geometry.FLOAT_EPSILON)

func test_ceiling_before_releasing_jump_button() -> void:
    # is_position_before_peak = true
    # is_position_before_instruction_end = true
    set_up({
        target_position_y = -100.0,
        position_instruction_end_y = -200.0,
        surface_side = SurfaceSide.CEILING,
        should_use_constraint = true,
        should_stay_on_min_side = true,
        position_start_y = 0.0,
        velocity_instruction_end_y = -300.0,
        time_instruction_end = 0.5,
    })
    var expected := 0.10495720687362033
    
    var actual := PlayerMovement._calculate_end_time_for_jumping_to_position(movement_params, \
            vertical_step, target_position, upcoming_constraint, destination_surface)

    assert_almost_eq(actual, expected, Geometry.FLOAT_EPSILON)

func test_ceiling_after_releasing_jump_button() -> void:
    # is_position_before_peak = true
    # is_position_before_instruction_end = false
    set_up({
        target_position_y = -110.0,
        position_instruction_end_y = -100.0,
        surface_side = SurfaceSide.CEILING,
        should_use_constraint = true,
        should_stay_on_min_side = true,
        position_start_y = 0.0,
        velocity_instruction_end_y = -500.0,
        time_instruction_end = 0.5,
    })
    var expected := 0.522540333075851664

    
    var actual := PlayerMovement._calculate_end_time_for_jumping_to_position(movement_params, \
            vertical_step, target_position, upcoming_constraint, destination_surface)

    assert_almost_eq(actual, expected, Geometry.FLOAT_EPSILON)

func test_left_wall_with_should_stay_on_min_side_before_releasing() -> void:
    # is_position_before_peak = true
    # is_position_before_instruction_end = true
    set_up({
        target_position_y = -100.0,
        position_instruction_end_y = -200.0,
        surface_side = SurfaceSide.LEFT_WALL,
        should_use_constraint = true,
        should_stay_on_min_side = true,
        position_start_y = 0.0,
        velocity_instruction_end_y = -300.0,
        time_instruction_end = 0.5,
    })
    var expected := 0.10495720687362033
    
    var actual := PlayerMovement._calculate_end_time_for_jumping_to_position(movement_params, \
            vertical_step, target_position, upcoming_constraint, destination_surface)

    assert_almost_eq(actual, expected, Geometry.FLOAT_EPSILON)

func test_left_wall_with_should_stay_on_min_side_after_releasing() -> void:
    # is_position_before_peak = true
    # is_position_before_instruction_end = false
    set_up({
        target_position_y = -110.0,
        position_instruction_end_y = -100.0,
        surface_side = SurfaceSide.LEFT_WALL,
        should_use_constraint = true,
        should_stay_on_min_side = true,
        position_start_y = 0.0,
        velocity_instruction_end_y = -500.0,
        time_instruction_end = 0.5,
    })
    var expected := 0.522540333075851664
    
    var actual := PlayerMovement._calculate_end_time_for_jumping_to_position(movement_params, \
            vertical_step, target_position, upcoming_constraint, destination_surface)

    assert_almost_eq(actual, expected, Geometry.FLOAT_EPSILON)

func test_left_wall_without_should_stay_on_min_side() -> void:
    # is_position_before_peak = false
    # is_position_before_instruction_end = false
    set_up({
        target_position_y = -110.0,
        position_instruction_end_y = -100.0,
        surface_side = SurfaceSide.LEFT_WALL,
        should_use_constraint = true,
        should_stay_on_min_side = false,
        position_start_y = 0.0,
        velocity_instruction_end_y = -500.0,
        time_instruction_end = 0.5,
    })
    var expected := 0.67745966692414833
    
    var actual := PlayerMovement._calculate_end_time_for_jumping_to_position(movement_params, \
            vertical_step, target_position, upcoming_constraint, destination_surface)

    assert_almost_eq(actual, expected, Geometry.FLOAT_EPSILON)

func test_left_wall_without_constraint() -> void:
    # is_position_before_peak = false
    # is_position_before_instruction_end = false
    set_up({
        target_position_y = -110.0,
        position_instruction_end_y = -100.0,
        surface_side = SurfaceSide.LEFT_WALL,
        should_use_constraint = false,
        should_stay_on_min_side = true,
        position_start_y = 0.0,
        velocity_instruction_end_y = -500.0,
        time_instruction_end = 0.5,
    })
    var expected := 0.67745966692414833
    
    var actual := PlayerMovement._calculate_end_time_for_jumping_to_position(movement_params, \
            vertical_step, target_position, upcoming_constraint, destination_surface)

    assert_almost_eq(actual, expected, Geometry.FLOAT_EPSILON)

func test_right_wall_without_constraint() -> void:
    # is_position_before_peak = false
    # is_position_before_instruction_end = false
    set_up({
        target_position_y = -110.0,
        position_instruction_end_y = -100.0,
        surface_side = SurfaceSide.RIGHT_WALL,
        should_use_constraint = false,
        should_stay_on_min_side = true,
        position_start_y = 0.0,
        velocity_instruction_end_y = -500.0,
        time_instruction_end = 0.5,
    })
    var expected := 0.67745966692414833
    
    var actual := PlayerMovement._calculate_end_time_for_jumping_to_position(movement_params, \
            vertical_step, target_position, upcoming_constraint, destination_surface)

    assert_almost_eq(actual, expected, Geometry.FLOAT_EPSILON)
