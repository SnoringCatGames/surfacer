# A collection of utility functions for calculating state related to horizontal movement.
class_name HorizontalMovementUtils

const MovementCalcStep := preload("res://framework/movement/models/movement_calculation_step.gd")

# Calculates a new step for the current horizontal part of the movement.
static func calculate_horizontal_step(local_calc_params: MovementCalcLocalParams, \
        global_calc_params: MovementCalcGlobalParams) -> MovementCalcStep:
    var movement_params := global_calc_params.movement_params
    var vertical_step := local_calc_params.vertical_step
    
    var start_constraint := local_calc_params.start_constraint
    var position_step_start := start_constraint.position
    var time_step_start := start_constraint.time_passing_through
    
    var end_constraint := local_calc_params.end_constraint
    var position_end := end_constraint.position
    var time_step_end := end_constraint.time_passing_through
    var velocity_end_x := end_constraint.actual_velocity_x
    
    var step_duration := time_step_end - time_step_start
    var displacement := position_end - position_step_start
    
    # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE: -A
#    if position_step_start == Vector2(-2, -483) and position_end == Vector2(-128, -478):
#        print("yo")
    
    var horizontal_acceleration_sign: int
    var acceleration: float
    var velocity_start_x: float
    var should_accelerate_at_start: bool
    
    # Calculate the velocity_start_x, the direction of acceleration, and whether we should
    # accelerate at the start of the step or at the end of the step.
    if end_constraint.horizontal_movement_sign != start_constraint.horizontal_movement_sign:
        # If the start and end velocities are in opposition horizontal directions, then there is
        # only one possible acceleration direction.
        
        horizontal_acceleration_sign = end_constraint.horizontal_movement_sign
        acceleration = \
                movement_params.in_air_horizontal_acceleration * horizontal_acceleration_sign
            
        # First, try accelerating at the start of the step, then at the end.
        for try_accelerate_at_start in [true, false]:
            velocity_start_x = calculate_min_speed_velocity_start_x( \
                    start_constraint.horizontal_movement_sign, displacement.x, \
                    start_constraint.min_velocity_x, start_constraint.max_velocity_x, \
                    velocity_end_x, acceleration, step_duration, try_accelerate_at_start)
            
            if velocity_start_x != INF:
                # We found a valid start velocity.
                should_accelerate_at_start = try_accelerate_at_start
                break
        
    else:
        # If the start and end velocities are in the same horizontal direction, then it's possible
        # for the acceleration to be in either direction.
        
        # Since we generally want to try to minimize movement (and minimize the speed at the start
        # of the step), we first attempt the acceleration direction that corresponds to that min
        # speed.
        var min_speed_x_v_0 := start_constraint.min_velocity_x if \
                start_constraint.horizontal_movement_sign > 0 else \
                start_constraint.max_velocity_x
        
        # Determine acceleration direction.
        var velocity_x_change := velocity_end_x - min_speed_x_v_0
        if velocity_x_change > 0:
            horizontal_acceleration_sign = 1
        elif velocity_x_change < 0:
            horizontal_acceleration_sign = -1
        else:
            horizontal_acceleration_sign = 0
        
        # First, try with the acceleration in one direction, then try the other.
        for sign_multiplier in [horizontal_acceleration_sign, -horizontal_acceleration_sign]:
            acceleration = movement_params.in_air_horizontal_acceleration * sign_multiplier
            
            # First, try accelerating at the start of the step, then at the end.
            for try_accelerate_at_start in [true, false]:
                velocity_start_x = calculate_min_speed_velocity_start_x( \
                        start_constraint.horizontal_movement_sign, displacement.x, \
                        start_constraint.min_velocity_x, start_constraint.max_velocity_x, \
                        velocity_end_x, acceleration, step_duration, try_accelerate_at_start)
                
                if velocity_start_x != INF:
                    # We found a valid start velocity.
                    should_accelerate_at_start = try_accelerate_at_start
                    break
            
            if velocity_start_x != INF:
                # We found a valid start velocity with acceleration in this direction.
                horizontal_acceleration_sign = sign_multiplier
                break
    
    if velocity_start_x == INF:
        # There is no start velocity that can reach the target end position/velocity/time.
        return null
    
    ### Calculate other state for step/instruction start/end.
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var duration_for_horizontal_acceleration := (velocity_end_x - velocity_start_x) / acceleration
    assert(step_duration >= duration_for_horizontal_acceleration)
    var duration_for_horizontal_coasting := step_duration - duration_for_horizontal_acceleration
    
    var time_instruction_start: float
    var time_instruction_end: float
    var position_instruction_start_x: float
    var position_instruction_end_x: float
    
    if should_accelerate_at_start:
        time_instruction_start = time_step_start
        time_instruction_end = time_step_start + duration_for_horizontal_acceleration
        
        position_instruction_start_x = position_step_start.x
        # From a basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        position_instruction_end_x = position_step_start.x + \
                velocity_start_x * duration_for_horizontal_acceleration + \
                0.5 * acceleration * \
                duration_for_horizontal_acceleration * duration_for_horizontal_acceleration
    else:
        time_instruction_start = time_step_end - duration_for_horizontal_acceleration
        time_instruction_end = time_step_end
        
        # From a basic equation of motion:
        #     s = s_0 + v_0*t
        position_instruction_start_x = \
                position_step_start.x + velocity_start_x * duration_for_horizontal_coasting
        position_instruction_end_x = position_end.x
    
    var step_start_state := VerticalMovementUtils.calculate_vertical_end_state_for_time( \
            movement_params, vertical_step, time_step_start)
    var instruction_start_state := VerticalMovementUtils.calculate_vertical_end_state_for_time( \
            movement_params, vertical_step, time_instruction_start)
    var instruction_end_state := VerticalMovementUtils.calculate_vertical_end_state_for_time( \
            movement_params, vertical_step, time_instruction_end)
    var step_end_state := VerticalMovementUtils.calculate_vertical_end_state_for_time( \
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
    
    start_constraint.actual_velocity_x = velocity_start_x
    
    return step

# Calculate the start velocity with the min possible speed to reach the given end position,
# velocity, and time. This min-speed start velocity corresponds to accelerating the most.
static func calculate_min_speed_velocity_start_x(horizontal_movement_sign_start: int, \
        displacement: float, v_start_min: float, v_start_max: float, v_end: float, \
        acceleration: float, duration: float, should_accelerate_at_start: bool) -> float:
    if displacement == 0:
        # If we don't need to move horizontally at all, then let's just use the start velocity with
        # the minimum possible speed. This could generate some false negatives, but such scenarios
        # seem unlikely.
        return v_start_min if horizontal_movement_sign_start > 0 else v_start_max
    
    var a: float
    var b: float
    var c: float
    
    # - Accelerating at the start, and coasting at the end, yields a smaller starting velocity
    #   (smaller directionally, not necessarily _slower_).
    # - Accelerating at the end, and coasting at the start, yields a larger starting velocity
    #   (larger directionally, not necessarily _faster_).
    if should_accelerate_at_start:
        # Try accelerating at the start of the step.
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant acceleration from v_0 to v_1.
        #   - Part 2: Coast at v_1 until we reach the destination.
        #   - The shorter part 1 is, the sooner we reach v_1 and the further we travel during
        #     part 2. This then means that we will need to have a lower v_0 and travel less far
        #     during part 1, which is good, since we want to choose a v_0 with the
        #     minimum-possible speed.
        # - Start with basic equations of motion
        # - v_1 = v_0 + a*t_1
        # - s_2 = s_1 + v_1*t_2
        # - v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
        # - t_total = t_1 + t_2
        # - Do some algebra...
        # - 0 = 2*a*(s_2 - s_0 - v_1*t_total) + v_1^2 - 2*v_1*v_0 + v_0^2
        # - Apply quadratic formula to solve for v_0.
        a = 1
        b = -2 * v_end
        c = 2 * acceleration * (displacement - v_end * duration) + v_end * v_end
    else:
        # Try accelerating at the end of the step.
        # Derivation:
        # - There are two parts:
        #   - Part 1: Coast at v_0 until we need to start accelerating.
        #   - Part 2: Constant acceleration from v_0 to v_1; we reach the destination when we reach v_1.
        #   - The longer part 1 is, the more we can accelerate during part 2, and the bigger v_1 can
        #     be.
        # - Start with basic equations of motion
        # - s_1 = s_0 + v_0*t_0
        # - v_1 = v_0 + a*t_1
        # - v_1^2 = v_0^2 + 2*a*(s_2 - s_1)
        # - t_total = t_0 + t_1
        # - Do some algebra...
        # - 0 = 2*a*(s_2 - s_0) - v_1^2 + 2*(v_1 - a*t_total)*v_0 - v_0^2
        # - Apply quadratic formula to solve for v_0.
        a = -1
        b = 2 * (v_end - acceleration * duration)
        c = 2 * acceleration * displacement - v_end * v_end
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # There is no start velocity that can satisfy these parameters.
        return INF
    
    var discriminant_sqrt := sqrt(discriminant)
    var result_1 := (-b + discriminant_sqrt) / 2 / a
    var result_2 := (-b - discriminant_sqrt) / 2 / a
    
    var min_speed_v_0_to_reach_target: float
    if horizontal_movement_sign_start > 0:
        # Choose the slowest result that is in the correct direction.
        if result_1 < 0 and result_2 < 0:
            # Movement must be in the expected direction, so neither result is a valid start
            # velocity.
            return INF
        elif result_1 < 0:
            min_speed_v_0_to_reach_target = result_2
        elif result_2 < 0:
            min_speed_v_0_to_reach_target = result_1
        else:
            min_speed_v_0_to_reach_target = min(result_1, result_2)
        
        if min_speed_v_0_to_reach_target > v_start_max:
            # We cannot start this step with enough speed to reach the end position.
            return INF
        elif min_speed_v_0_to_reach_target < v_start_min:
            # TODO: Check if this case is actually always an error
            Utils.error()

            # # The calculated min-speed start velocity is less than the min possible for this step,
            # # so let's try using the min possible for this step.
            # return v_start_min
            return INF
        else:
            # The calculated velocity is somewhere within the acceptable min/max range.
            return min_speed_v_0_to_reach_target
    else: 
        # horizontal_movement_sign_start < 0
        
        # Choose the slowest result that is in the correct direction.
        if result_1 > 0 and result_2 > 0:
            # Movement must be in the expected direction, so neither result is a valid start
            # velocity.
            return INF
        elif result_1 > 0:
            min_speed_v_0_to_reach_target = result_2
        elif result_2 > 0:
            min_speed_v_0_to_reach_target = result_1
        else:
            min_speed_v_0_to_reach_target = max(result_1, result_2)
        
        if min_speed_v_0_to_reach_target < v_start_min:
            # We cannot start this step with enough speed to reach the end position.
            return INF
        elif min_speed_v_0_to_reach_target > v_start_max:
            # TODO: Check if this case is actually always an error
            Utils.error()

            # # The calculated min-speed start velocity is greater than the max possible for this
            # # step, so let's try using the max possible for this step.
            # return v_start_max
            return INF
        else:
            # The calculated velocity is somewhere within the acceptable min/max range.
            return min_speed_v_0_to_reach_target

# Calculates the horizontal component of position and velocity according to the given horizontal
# movement state and the given time. These are then returned in a Vector2: x is position and y is
# velocity.
static func calculate_horizontal_end_state_for_time(movement_params: MovementParams, \
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
