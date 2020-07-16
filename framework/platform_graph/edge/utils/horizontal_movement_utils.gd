# A collection of utility functions for calculating state related to horizontal
# movement.
extends Reference
class_name HorizontalMovementUtils

const MIN_MAX_VELOCITY_X_MARGIN := WaypointUtils.MIN_MAX_VELOCITY_X_OFFSET * 10

# Calculates a new step for the current horizontal part of the movement.
static func calculate_horizontal_step( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        step_calc_params: EdgeStepCalcParams, \
        edge_calc_params: EdgeCalcParams) -> EdgeStep:
    Profiler.start( \
            ProfilerMetric.CALCULATE_HORIZONTAL_STEP, \
            edge_calc_params.collision_params.thread_id)
    
    var movement_params := edge_calc_params.movement_params
    var vertical_step := step_calc_params.vertical_step
    
    var start_waypoint := step_calc_params.start_waypoint
    var position_step_start := start_waypoint.position
    var time_step_start := start_waypoint.time_passing_through
    
    var end_waypoint := step_calc_params.end_waypoint
    var position_end := end_waypoint.position
    var time_step_end := end_waypoint.time_passing_through
    var velocity_start_x := start_waypoint.actual_velocity_x
    
    var step_duration := time_step_end - time_step_start
    var displacement := position_end - position_step_start
    
    ### Calculate the end x-velocity, the direction of acceleration,
    ### acceleration start time, and acceleration end time.
    
    var min_and_max_velocity_at_step_end := \
            _calculate_min_and_max_x_velocity_at_end_of_interval( \
                    displacement.x, \
                    step_duration, \
                    velocity_start_x, \
                    end_waypoint.min_velocity_x, \
                    end_waypoint.max_velocity_x, \
                    movement_params.in_air_horizontal_acceleration)
    if min_and_max_velocity_at_step_end.empty():
        # This waypoint cannot be reached.
        Profiler.stop_with_optional_metadata( \
                ProfilerMetric.CALCULATE_HORIZONTAL_STEP, \
                edge_calc_params.collision_params.thread_id, \
                edge_result_metadata)
        return null
    var min_velocity_end_x: float = min_and_max_velocity_at_step_end[0]
    var max_velocity_end_x: float = min_and_max_velocity_at_step_end[1]
    
    # There's no need to add an epsilon offset here, since the offset was added
    # when calculating the min/max in the first place.
    var velocity_end_x: float
    if movement_params.minimizes_velocity_change_when_jumping:
        velocity_end_x = \
                0.0 if \
                min_velocity_end_x <= 0 and \
                max_velocity_end_x >= 0 else \
                min_velocity_end_x if \
                abs(min_velocity_end_x) < abs(max_velocity_end_x) else \
                max_velocity_end_x
    else:
        velocity_end_x = \
                max_velocity_end_x if \
                abs(min_velocity_end_x) < abs(max_velocity_end_x) else \
                min_velocity_end_x
    
    var horizontal_acceleration_sign := \
            -1 if \
            velocity_end_x - velocity_start_x < 0 else \
            1
    var acceleration := \
            movement_params.in_air_horizontal_acceleration * \
            horizontal_acceleration_sign
    
    var acceleration_start_and_end_time := \
            _calculate_acceleration_start_and_end_time( \
                    displacement.x, \
                    step_duration, \
                    velocity_start_x, \
                    velocity_end_x, \
                    acceleration)
    if acceleration_start_and_end_time.empty():
        # There is no start velocity that can reach the target end
        # position/velocity/time. This should never happen, since we should
        # have failed earlier during waypoint calculations.
        Utils.error()
        Profiler.stop_with_optional_metadata( \
                ProfilerMetric.CALCULATE_HORIZONTAL_STEP, \
                edge_calc_params.collision_params.thread_id, \
                edge_result_metadata)
        return null
    var time_instruction_start: float = \
            time_step_start + acceleration_start_and_end_time[0]
    var time_instruction_end: float = \
            time_step_start + acceleration_start_and_end_time[1]
    
    ### Calculate other state for step/instruction start/end.
    
    var duration_during_initial_coast := \
            time_instruction_start - time_step_start
    var duration_during_horizontal_acceleration := \
            time_instruction_end - time_instruction_start
    
    # From a basic equation of motion:
    #     s = s_0 + v_0*t
    var displacement_x_during_initial_coast := \
            velocity_start_x * duration_during_initial_coast
    # From a basic equation of motion:
    #     s = s_0 + v_0*t + 1/2*a*t^2
    var displacement_x_during_acceleration := \
            velocity_start_x * duration_during_horizontal_acceleration + \
            0.5 * acceleration * duration_during_horizontal_acceleration * \
            duration_during_horizontal_acceleration
    
    var position_instruction_start_x := \
            position_step_start.x + displacement_x_during_initial_coast
    var position_instruction_end_x := \
            position_instruction_start_x + displacement_x_during_acceleration
    
    var step_start_state := VerticalMovementUtils \
            .calculate_vertical_state_for_time_from_step( \
                    movement_params, \
                    vertical_step, \
                    time_step_start)
    var instruction_start_state := VerticalMovementUtils \
            .calculate_vertical_state_for_time_from_step( \
                    movement_params, \
                    vertical_step, \
                    time_instruction_start)
    var instruction_end_state := VerticalMovementUtils \
            .calculate_vertical_state_for_time_from_step( \
                    movement_params, \
                    vertical_step, \
                    time_instruction_end)
    var step_end_state := VerticalMovementUtils \
            .calculate_vertical_state_for_time_from_step( \
                    movement_params, \
                    vertical_step, \
                    time_step_end)
    
    assert(Geometry.are_floats_equal_with_epsilon( \
            step_end_state[0], \
            position_end.y, \
            0.2))
    assert(Geometry.are_floats_equal_with_epsilon( \
            step_start_state[0], \
            position_step_start.y, \
            0.2))
    
    ### Assign the step properties.
    
    var step := EdgeStep.new()
    
    step.horizontal_acceleration_sign = horizontal_acceleration_sign
    
    step.time_step_start = time_step_start
    step.time_instruction_start = time_instruction_start
    step.time_instruction_end = time_instruction_end
    step.time_step_end = time_step_end
    
    step.position_step_start = position_step_start
    step.position_instruction_start = \
            Vector2(position_instruction_start_x, instruction_start_state[0])
    step.position_instruction_end = \
            Vector2(position_instruction_end_x, instruction_end_state[0])
    step.position_step_end = position_end
    
    step.velocity_step_start = Vector2(velocity_start_x, step_start_state[1])
    step.velocity_instruction_start = \
            Vector2(velocity_start_x, instruction_start_state[1])
    step.velocity_instruction_end = \
            Vector2(velocity_end_x, instruction_end_state[1])
    step.velocity_step_end = Vector2(velocity_end_x, step_end_state[1])
    
    end_waypoint.actual_velocity_x = velocity_end_x
    
    Profiler.stop_with_optional_metadata( \
            ProfilerMetric.CALCULATE_HORIZONTAL_STEP, \
            edge_calc_params.collision_params.thread_id, \
            edge_result_metadata)
    
    return step

# Calculate the times that accelaration starts and stops in order for movement
# to match the given parameters.
# 
# This assumes a three-part movement profile:
# 1.  Constant velocity
# 2.  Constant acceleration
# 3.  Constant velocity
static func _calculate_acceleration_start_and_end_time( \
        displacement: float, \
        duration: float, \
        velocity_start: float, \
        velocity_end: float, \
        acceleration: float) -> Array:
    var velocity_change := velocity_start - velocity_end
    
    if velocity_change == 0:
        # We don't need to accelerate at all.
        return [0.0, 0.0]
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var duration_during_acceleration := \
            (velocity_end - velocity_start) / acceleration
    
    ## Derivation:
    # - There are three parts:
    #   - Part 1: Constant velocity at v_0 (from s_0 to s_1).
    #   - Part 1: Constant acceleration from v_0 to v_1 (and from s_1 to s_2).
    #   - Part 2: Constant velocity at v_1 (from s_2 to s_3).
    # - Start with basic equations of motion:
    #   - s_1 = s_0 + v_0*t_0
    #   - v_1 = v_0 + a*t_1
    #   - s_3 = s_2 + v_1*t_2
    #   - v_1^2 = v_0^2 + 2*a*(s_2 - s_1)
    #   - t_total = t_0 + t_1 + t_2
    # - Do some algebra...
    #   - t_0 = ((s_3 - s_0) + v_1*(t_1 - t_total) + (v_0^2 - v_1^2)/2/a) /
    #           (v_0 - v_1)
    var duration_during_initial_coast := \
            (displacement + velocity_end * \
            (duration_during_acceleration - duration) + \
            (velocity_start * velocity_start - velocity_end * velocity_end) / \
            2 / acceleration) / velocity_change
    
    var time_acceleration_start := duration_during_initial_coast
    var time_acceleration_end := \
            time_acceleration_start + duration_during_acceleration
    
    if Geometry.are_floats_equal_with_epsilon(time_acceleration_end, duration):
        time_acceleration_end = duration
    
    if duration_during_acceleration < 0 or time_acceleration_end > duration:
        # Something went wrong.
        Utils.error()
        return []
    
    return [time_acceleration_start, time_acceleration_end]

# Calculates the horizontal component of position and velocity according to the
# given horizontal movement state and the given time. These are then returned
# in an Array: [0] is position and [1] is velocity.
static func calculate_horizontal_state_for_time( \
        movement_params: MovementParams, \
        horizontal_step: EdgeStep, \
        time: float) -> Array:
    assert(time >= horizontal_step.time_step_start - Geometry.FLOAT_EPSILON)
    assert(time <= horizontal_step.time_step_end + Geometry.FLOAT_EPSILON)
    
    var position: float
    var velocity: float
    if time <= horizontal_step.time_instruction_start:
        var delta_time := time - horizontal_step.time_step_start
        velocity = horizontal_step.velocity_step_start.x
        # From a basic equation of motion:
        #     s = s_0 + v*t
        position = horizontal_step.position_step_start.x + \
                velocity * delta_time
        
    elif time >= horizontal_step.time_instruction_end:
        var delta_time := time - horizontal_step.time_instruction_end
        velocity = horizontal_step.velocity_instruction_end.x
        # From a basic equation of motion:
        #     s = s_0 + v*t
        position = horizontal_step.position_instruction_end.x + \
                velocity * delta_time
        
    else:
        var delta_time := time - horizontal_step.time_instruction_start
        var acceleration := movement_params.in_air_horizontal_acceleration * \
                horizontal_step.horizontal_acceleration_sign
        # From basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        position = horizontal_step.position_instruction_start.x + \
                horizontal_step.velocity_step_start.x * delta_time + \
                0.5 * acceleration * delta_time * delta_time
        # From basic equation of motion:
        #     v = v_0 + a*t
        velocity = horizontal_step.velocity_step_start.x + \
                acceleration * delta_time
    
    assert(velocity <= movement_params.max_horizontal_speed_default + 0.001)
    
    return [position, velocity]

static func calculate_max_horizontal_displacement_before_returning_to_starting_height( \
        velocity_start_x: float, \
        velocity_start_y: float, \
        max_horizontal_speed_default: float, \
        gravity_slow_rise: float, \
        gravity_fast_fall: float) -> float:
    # FIXME: D: Use velocity_start_x, and account for acceleration, in order to
    #           further limit the displacement.
    # FIXME: F: Add support for double jumps, dash, etc.
    # FIXME: A: Add horizontal acceleration
    
    assert(velocity_start_y < 0.0)
    
    # v = v_0 + a*t
    var max_time_to_peak := -velocity_start_y / gravity_slow_rise
    # s = s_0 + v_0*t + 0.5*a*t*t
    var max_peak_height := velocity_start_y * max_time_to_peak + \
            0.5 * gravity_slow_rise * max_time_to_peak * max_time_to_peak
    # v^2 = v_0^2 + 2*a*(s - s_0)
    var max_velocity_when_returning_to_starting_height := \
            sqrt(2 * gravity_fast_fall * -max_peak_height)
    # v = v_0 + a*t
    var max_time_for_fall_from_peak_to_starting_height := \
            max_velocity_when_returning_to_starting_height / gravity_fast_fall
    # Rise time plus fall time.
    var max_time_to_starting_height := \
            max_time_to_peak + max_time_for_fall_from_peak_to_starting_height
    # s = s_0 + v * t
    return max_time_to_starting_height * max_horizontal_speed_default

static func _calculate_min_and_max_x_velocity_at_end_of_interval( \
        displacement: float, \
        duration: float, \
        velocity_start: float, \
        min_velocity_end_for_valid_next_step: float, \
        max_velocity_end_for_valid_next_step: float, \
        acceleration_magnitude: float) -> Array:
    var acceleration_sign_for_min := \
            1 if \
            min_velocity_end_for_valid_next_step >= velocity_start else \
            -1
    var acceleration_for_min := \
            acceleration_magnitude * acceleration_sign_for_min
    # -   For positive acceleration, accelerating at the start of the step will
    #     give us the min end velocity.
    # -   For negative acceleration, accelerating at the end of the step will
    #     give us the min end velocity.
    var should_accelerate_at_start_for_min := acceleration_sign_for_min == 1
    
    var min_velocity_end := WaypointUtils._solve_for_end_velocity( \
            displacement, \
            duration, \
            acceleration_for_min, \
            velocity_start, \
            should_accelerate_at_start_for_min, \
            true)
    if min_velocity_end == INF:
        min_velocity_end = WaypointUtils._solve_for_end_velocity( \
                displacement, \
                duration, \
                -acceleration_for_min, \
                velocity_start, \
                !should_accelerate_at_start_for_min, \
                true)
    # Round-off error can cause this to be slightly higher than max-speed
    # sometimes.
    if min_velocity_end < max_velocity_end_for_valid_next_step + 0.0001:
        min_velocity_end = \
                min(min_velocity_end, max_velocity_end_for_valid_next_step)
    if min_velocity_end == INF or \
            min_velocity_end > max_velocity_end_for_valid_next_step:
        # Movement cannot reach across this interval.
        return []
    
    var acceleration_sign_for_max := \
            1 if \
            max_velocity_end_for_valid_next_step >= velocity_start else \
            -1
    var acceleration_for_max := \
            acceleration_magnitude * acceleration_sign_for_max
    # -   For positive acceleration, accelerating at the start of the step will
    #     give us the max end velocity.
    # -   For negative acceleration, accelerating at the end of the step will
    #     give us the max end velocity.
    var should_accelerate_at_start_for_max := acceleration_sign_for_max == -1
    
    var max_velocity_end := WaypointUtils._solve_for_end_velocity( \
            displacement, \
            duration, \
            acceleration_for_max, \
            velocity_start, \
            should_accelerate_at_start_for_max, \
            false)
    if max_velocity_end == INF:
        max_velocity_end = WaypointUtils._solve_for_end_velocity( \
                displacement, \
                duration, \
                -acceleration_for_max, \
                velocity_start, \
                !should_accelerate_at_start_for_max, \
                false)
    # Round-off error can cause this to be slightly higher than max-speed
    # sometimes.
    if max_velocity_end > min_velocity_end_for_valid_next_step - 0.0001:
        max_velocity_end = \
                max(max_velocity_end, min_velocity_end_for_valid_next_step)
    # If we found valid min velocity, then we should be able to find valid max
    # velocity.
    assert(max_velocity_end != INF)
    if max_velocity_end < min_velocity_end_for_valid_next_step:
        # Movement cannot reach across this interval.
        return []
    
    # Account for round-off error.
    if Geometry.are_floats_equal_with_epsilon( \
            min_velocity_end, \
            max_velocity_end_for_valid_next_step, \
            0.001):
        min_velocity_end = max_velocity_end_for_valid_next_step
    if Geometry.are_floats_equal_with_epsilon( \
            max_velocity_end, \
            min_velocity_end_for_valid_next_step, \
            0.001):
        max_velocity_end = min_velocity_end_for_valid_next_step
    
    # FIXME: Remove?
#    assert(min_velocity_end <= max_velocity_end_for_valid_next_step)
#    assert(max_velocity_end >= min_velocity_end_for_valid_next_step)
    
    min_velocity_end = max(min_velocity_end, \
            min_velocity_end_for_valid_next_step)
    max_velocity_end = min(max_velocity_end, \
            max_velocity_end_for_valid_next_step)
    
    return [min_velocity_end, max_velocity_end]
