# A collection of utility functions for calculating state related to horizontal movement.
class_name HorizontalMovementUtils

const MovementCalcStep := preload("res://framework/movement/models/movement_calculation_step.gd")

const MIN_MAX_VELOCITY_X_MARGIN := MovementConstraintUtils.MIN_MAX_VELOCITY_X_OFFSET * 10

# Calculates a new step for the current horizontal part of the movement.
static func calculate_horizontal_step(step_calc_params: MovementCalcStepParams, \
        overall_calc_params: MovementCalcOverallParams) -> MovementCalcStep:
    var movement_params := overall_calc_params.movement_params
    var vertical_step := step_calc_params.vertical_step
    
    var start_constraint := step_calc_params.start_constraint
    var position_step_start := start_constraint.position
    var time_step_start := start_constraint.time_passing_through
    
    var end_constraint := step_calc_params.end_constraint
    var position_end := end_constraint.position
    var time_step_end := end_constraint.time_passing_through
    var velocity_start_x := start_constraint.actual_velocity_x
    
    var step_duration := time_step_end - time_step_start
    var displacement := position_end - position_step_start
    
    # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE: -A
#    if position_step_start == Vector2(-2, -483) and position_end == Vector2(-128, -478):
#        print("yo")
    
    ### Calculate the end x-velocity, the direction of acceleration, acceleration start time, and
    ### acceleration end time.
    
    # There's no need to add an epsilon offset here, since the offset was added when calculating
    # the min/max in the first place.
    var velocity_end_x := 0.0 if \
            end_constraint.min_velocity_x <= 0 and end_constraint.max_velocity_x >= 0 else \
            end_constraint.min_velocity_x if \
            abs(end_constraint.min_velocity_x) < abs(end_constraint.max_velocity_x) else \
            end_constraint.max_velocity_x
    
    var horizontal_acceleration_sign := -1 if velocity_end_x - velocity_start_x < 0 else 1
    var acceleration := \
            movement_params.in_air_horizontal_acceleration * horizontal_acceleration_sign
    
    var acceleration_start_and_end_time := _calculate_acceleration_start_and_end_time( \
            displacement.x, step_duration, velocity_start_x, velocity_end_x, acceleration)
    var time_instruction_start: float = time_step_start + acceleration_start_and_end_time[0]
    var time_instruction_end: float = time_step_start + acceleration_start_and_end_time[1]
    
    if acceleration_start_and_end_time.empty():
        # There is no start velocity that can reach the target end position/velocity/time.
        # This should never happen, since we should have failed earlier during constraint
        # calculations.
        Utils.error()
        return null
    
    ### Calculate other state for step/instruction start/end.
    
    var duration_during_initial_coast := time_instruction_start - time_step_start
    var duration_during_horizontal_acceleration := time_instruction_end - time_instruction_start
    
    # From a basic equation of motion:
    #     s = s_0 + v_0*t
    var displacement_x_during_initial_coast := \
            velocity_start_x * duration_during_horizontal_acceleration
    # From a basic equation of motion:
    #     s = s_0 + v_0*t + 1/2*a*t^2
    var displacement_x_during_acceleration := \
            velocity_start_x * duration_during_horizontal_acceleration + \
            0.5 * acceleration * duration_during_horizontal_acceleration * \
            duration_during_horizontal_acceleration
    
    var position_instruction_start_x := position_step_start.x + displacement_x_during_initial_coast
    var position_instruction_end_x := \
            position_instruction_start_x + displacement_x_during_acceleration
    
    var step_start_state := \
            VerticalMovementUtils.calculate_vertical_state_for_time_from_step( \
                    movement_params, vertical_step, time_step_start)
    var instruction_start_state := \
            VerticalMovementUtils.calculate_vertical_state_for_time_from_step( \
                    movement_params, vertical_step, time_instruction_start)
    var instruction_end_state := \
            VerticalMovementUtils.calculate_vertical_state_for_time_from_step( \
                    movement_params, vertical_step, time_instruction_end)
    var step_end_state := \
            VerticalMovementUtils.calculate_vertical_state_for_time_from_step( \
                    movement_params, vertical_step, time_step_end)
    
    assert(Geometry.are_floats_equal_with_epsilon(step_end_state[0], position_end.y, 0.0001))
    assert(Geometry.are_floats_equal_with_epsilon(step_start_state[0], position_step_start.y, 0.0001))
    
    ### Assign the step properties.
    
    var step := MovementCalcStep.new()
    
    step.horizontal_acceleration_sign = horizontal_acceleration_sign
    
    step.time_step_start = time_step_start
    step.time_instruction_start = time_instruction_start
    step.time_instruction_end = time_instruction_end
    step.time_step_end = time_step_end
    
    step.position_step_start = position_step_start
    step.position_instruction_start = Vector2(position_instruction_start_x, instruction_start_state[0])
    step.position_instruction_end = Vector2(position_instruction_end_x, instruction_end_state[0])
    step.position_step_end = position_end
    
    step.velocity_step_start = Vector2(velocity_start_x, step_start_state[1])
    step.velocity_instruction_start = Vector2(velocity_start_x, instruction_start_state[1])
    step.velocity_instruction_end = Vector2(velocity_end_x, instruction_end_state[1])
    step.velocity_step_end = Vector2(velocity_end_x, step_end_state[1])
    
    end_constraint.actual_velocity_x = velocity_end_x
    
    return step

# Calculate the times that accelaration starts and stops in order for movement to match the given parameters.
# 
# This assumes a three-part movement profile:
# 1.  Constant velocity
# 2.  Constant acceleration
# 3.  Constant velocity
static func _calculate_acceleration_start_and_end_time(displacement: float, duration: float, \
        velocity_start: float, velocity_end: float, acceleration: float) -> Array:
    var velocity_change := velocity_start - velocity_end
    
    if velocity_change == 0:
        # We don't need to accelerate at all.
        return [0.0, 0.0]
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var duration_during_acceleration := (velocity_end - velocity_start) / acceleration
    
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
    #   - t_0 = ((s_3 - s_0) + v_1*(t_1 - t_total) + (v_0^2 - v_1^2)/2/a) / (v_0 - v_1)
    var duration_during_initial_coast := \
            (displacement + velocity_end * (duration_during_acceleration - duration) + \
            (velocity_start * velocity_start - velocity_end * velocity_end) / 2 / acceleration) / \
            velocity_change
    
    var time_acceleration_start := duration_during_initial_coast
    var time_acceleration_end := time_acceleration_start + duration_during_acceleration
    
    if duration_during_acceleration < 0 or time_acceleration_end > duration:
        # Something went wrong.
        Utils.error()
        return []
    
    return [time_acceleration_start, time_acceleration_end]

# Calculates the horizontal component of position and velocity according to the given horizontal
# movement state and the given time. These are then returned in a Vector2: x is position and y is
# velocity.
static func calculate_horizontal_state_for_time(movement_params: MovementParams, \
        horizontal_step: MovementCalcStep, time: float) -> Array:
    assert(time >= horizontal_step.time_step_start - Geometry.FLOAT_EPSILON)
    assert(time <= horizontal_step.time_step_end + Geometry.FLOAT_EPSILON)
    
    var position: float
    var velocity: float
    if time <= horizontal_step.time_instruction_start:
        var delta_time := time - horizontal_step.time_step_start
        velocity = horizontal_step.velocity_step_start.x
        # From a basic equation of motion:
        #     s = s_0 + v*t
        position = horizontal_step.position_step_start.x + velocity * delta_time
        
    elif time >= horizontal_step.time_instruction_end:
        var delta_time := time - horizontal_step.time_instruction_end
        velocity = horizontal_step.velocity_instruction_end.x
        # From a basic equation of motion:
        #     s = s_0 + v*t
        position = horizontal_step.position_instruction_end.x + velocity * delta_time
        
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
        velocity = horizontal_step.velocity_step_start.x + acceleration * delta_time
    
    assert(velocity <= movement_params.max_horizontal_speed_default + 0.001)
    
    return [position, velocity]

static func calculate_max_horizontal_displacement( \
        movement_params: MovementParams, velocity_start_y: float) -> float:
    # FIXME: F: Add support for double jumps, dash, etc.
    # FIXME: A: Add horizontal acceleration
    
    # v = v_0 + a*t
    var max_time_to_peak := -velocity_start_y / movement_params.gravity_slow_ascent
    # s = s_0 + v_0*t + 0.5*a*t*t
    var max_peak_height := velocity_start_y * max_time_to_peak + \
            0.5 * movement_params.gravity_slow_ascent * max_time_to_peak * max_time_to_peak
    # v^2 = v_0^2 + 2*a*(s - s_0)
    var max_velocity_when_returning_to_starting_height := \
            sqrt(2 * movement_params.gravity_fast_fall * -max_peak_height)
    # v = v_0 + a*t
    var max_time_for_descent_from_peak_to_starting_height := \
            max_velocity_when_returning_to_starting_height / movement_params.gravity_fast_fall
    # Ascent time plus descent time.
    var max_time_to_starting_height := \
            max_time_to_peak + max_time_for_descent_from_peak_to_starting_height
    # s = s_0 + v * t
    return max_time_to_starting_height * movement_params.max_horizontal_speed_default
