extends IntegrationTestBed

# Expected values were calculated using a Google spreadsheet:
# https://docs.google.com/spreadsheets/d/1qERIm_R-GjgmPqFgHa8GhI71gWRkXkX3Sy6FgSJNqrA/edit

func test_without_backward_acceleration() -> void:
    var time_start := 0.0
    var time_step_end := 0.9
    var position_start := 0.0
    var position_end := 180.0
    var velocity_start := 0.0
    var acceleration_start := 1500.0
    var post_release_backward_acceleration := 0.0
    var returns_lower_result := true
    var expects_only_one_positive_result := false

    var result := Movement._calculate_time_to_release_acceleration(time_start, \
            time_step_end, position_start, position_end, velocity_start, acceleration_start, \
            post_release_backward_acceleration, returns_lower_result, \
            expects_only_one_positive_result)
    
    assert_almost_eq(result, 0.1450165565, Gs.geometry.FLOAT_EPSILON)

func test_with_backward_acceleration_and_lower_result() -> void:
    var time_start := 0.0
    var time_step_end := 0.9
    var position_start := 0.0
    var position_end := 180.0
    var velocity_start := 0.0
    var acceleration_start := 1500.0
    var post_release_backward_acceleration := -2000.0
    var returns_lower_result := true
    var expects_only_one_positive_result := false

    var result := Movement._calculate_time_to_release_acceleration(time_start, \
            time_step_end, position_start, position_end, velocity_start, acceleration_start, \
            post_release_backward_acceleration, returns_lower_result, \
            expects_only_one_positive_result)
    
    assert_almost_eq(result, 0.4057473174, Gs.geometry.FLOAT_EPSILON)

func test_with_backward_acceleration_and_higher_result() -> void:
    var time_start := 0.0
    var time_step_end := 0.9
    var position_start := 0.0
    var position_end := 180.0
    var velocity_start := 0.0
    var acceleration_start := 1500.0
    var post_release_backward_acceleration := 200.0
    var returns_lower_result := false
    var expects_only_one_positive_result := false

    var result := Movement._calculate_time_to_release_acceleration(time_start, \
            time_step_end, position_start, position_end, velocity_start, acceleration_start, \
            post_release_backward_acceleration, returns_lower_result, \
            expects_only_one_positive_result)
    
    assert_almost_eq(result, 1.71098231, Gs.geometry.FLOAT_EPSILON)

func test_cant_reach_destination() -> void:
    var time_start := 0.0
    var time_step_end := 0.9
    var position_start := 0.0
    var position_end := 180.0
    var velocity_start := 0.0
    var acceleration_start := 300.0
    var post_release_backward_acceleration := 0.0
    var returns_lower_result := true
    var expects_only_one_positive_result := false

    var result := Movement._calculate_time_to_release_acceleration(time_start, \
            time_step_end, position_start, position_end, velocity_start, acceleration_start, \
            post_release_backward_acceleration, returns_lower_result, \
            expects_only_one_positive_result)
    
    assert_eq(result, INF)

func test_zero_distance() -> void:
    var time_start := 0.0
    var time_step_end := 0.9
    var position_start := 0.0
    var position_end := 0.0
    var velocity_start := 0.0
    var acceleration_start := 1500.0
    var post_release_backward_acceleration := 0.0
    var returns_lower_result := true
    var expects_only_one_positive_result := false

    var result := Movement._calculate_time_to_release_acceleration(time_start, \
            time_step_end, position_start, position_end, velocity_start, acceleration_start, \
            post_release_backward_acceleration, returns_lower_result, \
            expects_only_one_positive_result)
    
    assert_eq(result, 0.0)

func test_non_zero_inputs() -> void:
    var time_start := 0.8
    var time_step_end := 1.7
    var position_start := 2.0
    var position_end := 182.0
    var velocity_start := -100.0
    var acceleration_start := 1500.0
    var post_release_backward_acceleration := -100.0
    var returns_lower_result := true
    var expects_only_one_positive_result := false

    var result := Movement._calculate_time_to_release_acceleration(time_start, \
            time_step_end, position_start, position_end, velocity_start, acceleration_start, \
            post_release_backward_acceleration, returns_lower_result, \
            expects_only_one_positive_result)
    
    assert_almost_eq(result, 0.2504809472, Gs.geometry.FLOAT_EPSILON)
