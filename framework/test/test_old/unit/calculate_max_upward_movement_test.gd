extends IntegrationTestBed

# Expected values were calculated using a Google spreadsheet:
# https://docs.google.com/spreadsheets/d/1qERIm_R-GjgmPqFgHa8GhI71gWRkXkX3Sy6FgSJNqrA/edit

func test_calculate_max_upward_movement() -> void:
    var movement_params := MovementParams.new()
    movement_params.jump_boost = -1000.0
    movement_params.gravity_fast_fall = 5000.0
    movement_params.gravity_slow_rise = 900.0
    movement_params.max_horizontal_speed_default = 400.0

    var result := PlayerParams.calculate_max_upward_movement(movement_params)

    assert_almost_eq(result, -555.5555556, Geometry.FLOAT_EPSILON)
