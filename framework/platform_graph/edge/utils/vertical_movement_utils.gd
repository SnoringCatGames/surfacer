# A collection of utility functions for calculating state related to vertical movement.
class_name VerticalMovementUtils

const MovementVertCalcStep := preload("res://framework/platform_graph/edge/calculation_models/movement_vertical_calculation_step.gd")

# Calculates a new step for the vertical part of the movement and the corresponding total jump
# duration.
static func calculate_vertical_step( \
        overall_calc_params: MovementCalcOverallParams) -> MovementVertCalcStep:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    
    var movement_params := overall_calc_params.movement_params
    var origin_constraint := overall_calc_params.origin_constraint
    var destination_constraint := overall_calc_params.destination_constraint
    var velocity_start := overall_calc_params.velocity_start
    var can_hold_jump_button := overall_calc_params.can_backtrack_on_height
    
    var position_start := origin_constraint.position
    var position_end := destination_constraint.position
    var time_step_end := destination_constraint.time_passing_through
    
    var time_instruction_end: float
    var position_instruction_end := Vector2.INF
    var velocity_instruction_end := Vector2.INF
    
    # Calculate instruction-end and peak-height state. These depend on whether or not we can hold
    # the jump button to manipulate the jump height. 
    if can_hold_jump_button:
        var displacement: Vector2 = position_end - position_start
        time_instruction_end = calculate_time_to_release_jump_button( \
                movement_params, time_step_end, displacement.y, velocity_start.y)
        if time_instruction_end == INF:
            # We can't reach the given displacement with the given duration.
            return null
        
        # Need to calculate these after the step is instantiated.
        position_instruction_end = Vector2.INF
        velocity_instruction_end = Vector2.INF
    else:
        time_instruction_end = 0.0
        position_instruction_end = position_start
        velocity_instruction_end = velocity_start
    
    # Given the time to release the jump button, calculate the time to reach the peak.
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var velocity_at_jump_button_release := velocity_start.y + \
            movement_params.gravity_slow_rise * time_instruction_end
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var duration_to_reach_peak_after_release := \
            -velocity_at_jump_button_release / movement_params.gravity_fast_fall
    var time_peak_height := time_instruction_end + duration_to_reach_peak_after_release
    time_peak_height = max(time_peak_height, 0.0)
    
    var step := MovementVertCalcStep.new()
    
    step.horizontal_acceleration_sign = destination_constraint.horizontal_movement_sign
    step.can_hold_jump_button = can_hold_jump_button
    
    step.time_step_start = 0.0
    step.time_instruction_start = 0.0
    step.time_instruction_end = time_instruction_end
    step.time_step_end = time_step_end
    step.time_peak_height = time_peak_height
    
    step.position_step_start = position_start
    step.position_instruction_start = position_start
    step.position_step_end = position_end
    
    step.velocity_step_start = velocity_start
    step.velocity_instruction_start = velocity_start
    
    var step_end_state := calculate_vertical_state_for_time_from_step( \
            movement_params, step, time_step_end)
    var peak_height_end_state := calculate_vertical_state_for_time_from_step( \
            movement_params, step, time_peak_height)
    
    assert(Geometry.are_floats_equal_with_epsilon(step_end_state[0], position_end.y, 0.001))
    
    step.position_peak_height = Vector2(INF, peak_height_end_state[0])
    step.velocity_step_end = Vector2(INF, step_end_state[1])
    
    if position_instruction_end == Vector2.INF:
        var instruction_end_state := calculate_vertical_state_for_time_from_step( \
                movement_params, step, time_instruction_end)
        position_instruction_end = Vector2(INF, instruction_end_state[0])
        velocity_instruction_end = Vector2(INF, instruction_end_state[1])
    
    step.position_instruction_end = position_instruction_end
    step.velocity_instruction_end = velocity_instruction_end
    
    return step

# Calculates the minimum possible time it would take to jump between the given positions.
# 
# The total duration of the jump is at least the greatest of a few durations:
# 
# -   The duration to reach the minimum peak height (i.e., how high upward we must jump to reach
#     a higher destination).
# -   The duration to reach a lower destination.
# -   The duration to cover the horizontal displacement.
# 
# However, that total duration still isn't enough if we cannot reach the horizontal
# displacement before we've already past the destination vertically on the upward side of the
# trajectory. In that case, we need to consider the minimum time for the upward and downward
# motion of the jump.
static func calculate_time_to_jump_to_constraint(movement_params: MovementParams, \
        displacement: Vector2, velocity_start: Vector2, \
        can_hold_jump_button_at_start: bool, must_reach_destination_on_descent := false) -> float:
    if displacement.y < -movement_params.max_upward_jump_distance:
        # We cannot jump high enough for the displacement.
        return INF
    
    if can_hold_jump_button_at_start:
        # If we can currently hold the jump button, then there is slow-ascent and
        # variable-jump-height to consider.
    
        ### Calculate the time needed to move upward.
        
        # Calculate how long it will take for the jump to reach some minimum peak height.
        # 
        # This takes into consideration the fast-fall mechanics (i.e., that a slower gravity is
        # applied until either the jump button is released or we hit the peak of the jump).
        var duration_to_reach_upward_displacement: float
        if displacement.y < 0:
            # Derivation:
            # - Start with basic equations of motion
            # - v_1^2 = v_0^2 + 2*a_0*(s_1 - s_0)
            # - v_2^2 = v_1^2 + 2*a_1*(s_2 - s_1)
            # - v_2 = 0
            # - s_0 = 0
            # - Do some algebra...
            # - s_1 = (1/2*v_0^2 + a_1*s_2) / (a_1 - a_0)
            var distance_to_release_button_for_shorter_jump := \
                    (0.5 * velocity_start.y * velocity_start.y + \
                    movement_params.gravity_fast_fall * displacement.y) / \
                    (movement_params.gravity_fast_fall - movement_params.gravity_slow_rise)
            if distance_to_release_button_for_shorter_jump < displacement.y:
                # We cannot jump high enough for the displacement. This should have been caught
                # earlier.
                Utils.error()
                return INF
            
            if distance_to_release_button_for_shorter_jump < 0:
                # We need more motion than just the initial jump boost to reach the destination.
                var time_to_release_jump_button: float = \
                        MovementUtils.calculate_movement_duration( \
                                distance_to_release_button_for_shorter_jump, velocity_start.y, \
                                movement_params.gravity_slow_rise, true, 0.0, false)
                assert(time_to_release_jump_button != INF)
            
                # From a basic equation of motion:
                #     v = v_0 + a*t
                var velocity_at_jump_button_release := velocity_start.y + \
                        movement_params.gravity_slow_rise * time_to_release_jump_button
        
                # From a basic equation of motion:
                #     v = v_0 + a*t
                var duration_to_reach_peak_after_release := \
                        -velocity_at_jump_button_release / movement_params.gravity_fast_fall
                assert(duration_to_reach_peak_after_release >= 0)
        
                duration_to_reach_upward_displacement = time_to_release_jump_button + \
                        duration_to_reach_peak_after_release
            else:
                # The initial jump boost is already more motion than we need to reach the destination.
                # 
                # In this case, we set up the vertical step to hit the end position while still
                # travelling upward.
                duration_to_reach_upward_displacement = MovementUtils.calculate_movement_duration( \
                        displacement.y, velocity_start.y, movement_params.gravity_fast_fall, \
                        !must_reach_destination_on_descent, 0.0, false)
        else:
            # We're jumping downward, so we don't need to reach any minimum peak height.
            duration_to_reach_upward_displacement = 0.0
        
        # Calculate how long it will take for the jump to reach some lower destination.
        var duration_to_reach_downward_displacement: float
        if displacement.y > 0:
            duration_to_reach_downward_displacement = MovementUtils.calculate_movement_duration( \
                    displacement.y, velocity_start.y, movement_params.gravity_fast_fall, false, \
                    0.0, true)
            assert(duration_to_reach_downward_displacement != INF)
        else:
            duration_to_reach_downward_displacement = 0.0
        
        var horizontal_acceleration_sign: int
        if displacement.x < 0:
            horizontal_acceleration_sign = -1
        elif displacement.x > 0:
            horizontal_acceleration_sign = 1
        else:
            horizontal_acceleration_sign = 0
    
        ### Calculate the time needed to move horizontally.
        
        var duration_to_reach_horizontal_displacement := \
                MovementUtils.calculate_time_for_displacement(displacement.x, \
                        velocity_start.x, movement_params.in_air_horizontal_acceleration * \
                        horizontal_acceleration_sign, movement_params.max_horizontal_speed_default)
        if duration_to_reach_horizontal_displacement == INF:
            # If we can't reach the destination with that acceleration direction, try the other
            # direction.
            horizontal_acceleration_sign = -horizontal_acceleration_sign
            duration_to_reach_horizontal_displacement = \
                    MovementUtils.calculate_time_for_displacement(displacement.x, \
                            velocity_start.x, movement_params.in_air_horizontal_acceleration * \
                            horizontal_acceleration_sign, \
                            movement_params.max_horizontal_speed_default)
        assert(duration_to_reach_horizontal_displacement >= 0 and \
                duration_to_reach_horizontal_displacement != INF)
        
        # From a basic equation of motion:
        #   v = v_0 + a*t
        var duration_to_reach_peak_from_start_for_max_jump := \
                (0.0 - velocity_start.y) / movement_params.gravity_slow_rise
        var displacement_from_peak_to_target := displacement.y + \
                movement_params.max_upward_jump_distance
        # From a basic equation of motion:
        #   - s = s_0 + v_0*t + 1/2*a*t^2
        #   - v_0 = 0
        #   - Algebra...
        #   - t = sqrt(2 * (s - s_0) / a)
        var duration_to_reach_target_from_peak_for_max_jump := sqrt(2 * \
                displacement_from_peak_to_target / movement_params.gravity_fast_fall)
        var duration_to_reach_target_with_max_jump_height := \
                duration_to_reach_peak_from_start_for_max_jump + \
                duration_to_reach_target_from_peak_for_max_jump
        
        # The total duration is too much if the horizontal displacement requires more air time than
        # our highest jump affords.
        if duration_to_reach_target_with_max_jump_height < \
                duration_to_reach_horizontal_displacement:
            # We can't reach the horizontal displacement.
            return INF
        
        ### Calculate the time needed to move downward.
        
        var duration_to_reach_upward_displacement_on_descent := 0.0
        if duration_to_reach_downward_displacement == 0.0:
            # The total duration still isn't enough if we cannot reach the horizontal displacement
            # before we've already past the destination vertically on the upward side of the
            # trajectory. In that case, we need to consider the minimum time for the upward and
            # downward motion of the jump.
            
            var duration_to_reach_upward_displacement_with_only_fast_fall = \
                    MovementUtils.calculate_movement_duration(displacement.y, velocity_start.y, \
                            movement_params.gravity_fast_fall, true, 0.0, false)
            
            if duration_to_reach_upward_displacement_with_only_fast_fall != INF and \
                    duration_to_reach_upward_displacement_with_only_fast_fall < \
                    duration_to_reach_horizontal_displacement:
                duration_to_reach_upward_displacement_on_descent = \
                        MovementUtils.calculate_movement_duration(displacement.y, velocity_start.y, \
                                movement_params.gravity_fast_fall, false, 0.0, false)
                assert(duration_to_reach_upward_displacement_on_descent != INF)
        
        ### Use the max of each aspect of jump movement.
        
        # How high we need to jump is determined by the total duration of the jump.
        # 
        # The total duration of the jump is at least the greatest of three durations:
        # - The duration to reach the minimum peak height (i.e., how high upward we must jump to reach
        #   a higher destination).
        # - The duration to reach a lower destination.
        # - The duration to cover the horizontal displacement.
        # 
        # However, that total duration still isn't enough if we cannot reach the horizontal
        # displacement before we've already past the destination vertically on the upward side of the
        # trajectory. In that case, we need to consider the minimum time for the upward and downward
        # motion of the jump.
        return max(max(max(duration_to_reach_upward_displacement, \
                duration_to_reach_downward_displacement), \
                duration_to_reach_horizontal_displacement), \
                duration_to_reach_upward_displacement_on_descent)
    else:
        # If we can't currently hold the jump button, then there is no slow-ascent and variable
        # jump height to consider. So our movement duration is a lot simpler to calculate.
        return MovementUtils.calculate_movement_duration(displacement.y, velocity_start.y, \
                movement_params.gravity_fast_fall, false, 0.0, false, true)

# Given the total duration, calculate the time to release the jump button.
static func calculate_time_to_release_jump_button(movement_params: MovementParams, \
        duration: float, displacement_y: float, velocity_start_y: float) -> float:
    # Derivation:
    # - Start with basic equations of motion
    # - s_1 = s_0 + v_0*t_0 + 1/2*a_0*t_0^2
    # - s_2 = s_1 + v_1*t_1 + 1/2*a_1*t_1^2
    # - t_2 = t_0 + t_1
    # - v_1 = v_0 + a_0*t_0
    # - Do some algebra...
    # - 0 = (1/2*(a_1 - a_0))*t_0^2 + (t_2*(a_0 - a_1))*t_0 + (s_0 - s_2 + v_0*t_2 + 1/2*a_1*t_2^2)
    # - Apply quadratic formula to solve for t_0.
    var a := 0.5 * (movement_params.gravity_fast_fall - movement_params.gravity_slow_rise)
    var b := duration * (movement_params.gravity_slow_rise - movement_params.gravity_fast_fall)
    var c := -displacement_y + velocity_start_y * duration + \
            0.5 * movement_params.gravity_fast_fall * duration * duration
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # We can't reach the end position from our start position in the given time.
        return INF
    var discriminant_sqrt := sqrt(discriminant)
    var t1 := (-b - discriminant_sqrt) / 2.0 / a
    var t2 := (-b + discriminant_sqrt) / 2.0 / a
    
    var time_to_release_jump_button: float
    if t1 < -Geometry.FLOAT_EPSILON:
        time_to_release_jump_button = t2
    elif t2 < -Geometry.FLOAT_EPSILON:
        time_to_release_jump_button = t1
    else:
        time_to_release_jump_button = min(t1, t2)
    assert(time_to_release_jump_button >= -Geometry.FLOAT_EPSILON)
    
    time_to_release_jump_button = max(time_to_release_jump_button, 0.0)
    assert(time_to_release_jump_button <= duration)
    
    if time_to_release_jump_button > movement_params.time_to_max_upward_jump_distance:
        # FIXME: B: This if statement shouldn't be needed; the above discriminant should have
        #           accounted for the peak jump height already.
        return INF
    
    return time_to_release_jump_button

# Calculates the time at which the movement would travel through the given position with the
# given vertical_step.
# FIXME: B: Update unit tests to include min_end_time.
static func calculate_time_for_passing_through_constraint(movement_params: MovementParams, \
        constraint: MovementConstraint, min_end_time: float, position_start_y: float, \
        velocity_start_y: float, time_instruction_end: float, position_instruction_end_y: float, \
        velocity_instruction_end_y: float) -> float:
    var position := constraint.position

    var target_height := position.y
    
    var duration_of_slow_ascent: float
    var duration_of_fast_fall: float
    
    var is_position_before_instruction_end: bool
    var is_position_before_peak: bool
    
    # We need to know whether the position corresponds to the rising or falling side of the jump
    # parabola, and whether the position corresponds to before or after the jump button is
    # released.
    match constraint.surface.side:
        SurfaceSide.FLOOR:
            # Jump reaches the position after releasing the jump button (and after the peak).
            is_position_before_instruction_end = false
            is_position_before_peak = false
        SurfaceSide.CEILING:
            # Jump reaches the position before the peak.
            is_position_before_peak = true
            
            if target_height > position_start_y:
                return INF
            
            if target_height > position_instruction_end_y:
                # Jump reaches the position before releasing the jump button.
                is_position_before_instruction_end = true
            else:
                # Jump reaches the position after releasing the jump button (but before the
                # peak).
                is_position_before_instruction_end = false
        _: # A wall.
            if !constraint.is_destination:
                # We are considering an intermediate constraint.
                if constraint.should_stay_on_min_side:
                    # Passing over the top of the wall (jump reaches the position before the peak).
                    is_position_before_peak = true
                    
                    # FIXME: Double-check whether the vertical_step calculations will have actually
                    #        supported upward velocity at this point, or whether it will be forcing
                    #        downward?
                    
                    # We assume that we will always use upward velocity when passing over a
                    # wall.
                    if target_height > position_instruction_end_y:
                        # Jump reaches the position before releasing the jump button.
                        is_position_before_instruction_end = true
                    else:
                        # Jump reaches the position after releasing the jump button.
                        is_position_before_instruction_end = false
                else:
                    # Passing under the bottom of the wall (jump reaches the position after
                    # releasing the jump button and after the peak).
                    is_position_before_instruction_end = false
                    is_position_before_peak = false
            else:
                # We are considering a destination surface.
                # We assume destination walls will always use downward velocity at the end.
                is_position_before_instruction_end = false
                is_position_before_peak = false
    
    if is_position_before_instruction_end:
        var displacement := target_height - position_start_y
        duration_of_slow_ascent = MovementUtils.calculate_movement_duration(displacement, \
                velocity_start_y, movement_params.gravity_slow_rise, true, min_end_time, false)
        if duration_of_slow_ascent == INF:
            return INF
        duration_of_fast_fall = 0.0
    else:
        duration_of_slow_ascent = time_instruction_end
        min_end_time = max(min_end_time - duration_of_slow_ascent, 0.0)
        var displacement_of_fast_fall := target_height - position_instruction_end_y
        duration_of_fast_fall = MovementUtils.calculate_movement_duration( \
                displacement_of_fast_fall, velocity_instruction_end_y, \
                movement_params.gravity_fast_fall, is_position_before_peak, min_end_time, false)
        if duration_of_fast_fall == INF:
            return INF
    
    return duration_of_fast_fall + duration_of_slow_ascent

static func calculate_vertical_state_for_time_from_step(movement_params: MovementParams, \
        step: MovementVertCalcStep, time: float) -> Array:
    return calculate_vertical_state_for_time(movement_params, time, \
            step.position_step_start.y, step.velocity_step_start.y, \
            step.time_instruction_end)

# Calculates the vertical component of position and velocity according to the given vertical
# movement state and the given time. These are then returned in a Vector2: x is position and y is
# velocity.
# FIXME: B: Fix unit tests to use the return value instead of output params.
static func calculate_vertical_state_for_time(movement_params: MovementParams, time: float, \
        position_step_start_y: float, velocity_step_start_y: float, \
        time_jump_release: float) -> Array:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    var slow_ascent_end_time := min(time, time_jump_release)
    
    # Basic equations of motion.
    var slow_ascent_end_position := position_step_start_y + velocity_step_start_y * slow_ascent_end_time + \
            0.5 * movement_params.gravity_slow_rise * slow_ascent_end_time * slow_ascent_end_time
    var slow_ascent_end_velocity := velocity_step_start_y + \
            movement_params.gravity_slow_rise * slow_ascent_end_time
    
    var position: float
    var velocity: float
    if time_jump_release >= time:
        # We only need to consider the slow-ascent parabolic section.
        position = slow_ascent_end_position
        velocity = slow_ascent_end_velocity
    else:
        # We need to consider both the slow-ascent and fast-fall parabolic sections.
        
        var fast_fall_duration := time - slow_ascent_end_time
        
        # Basic equations of motion.
        position = slow_ascent_end_position + \
                slow_ascent_end_velocity * fast_fall_duration + \
                0.5 * movement_params.gravity_fast_fall * fast_fall_duration * fast_fall_duration
        velocity = slow_ascent_end_velocity + \
                movement_params.gravity_fast_fall * fast_fall_duration
    
    return [position, velocity]

# Returns a positive value.
static func calculate_max_upward_distance(movement_params: MovementParams) -> float:
    # FIXME: F: Add support for double jumps, dash, etc.
    
    # From a basic equation of motion:
    # - v^2 = v_0^2 + 2*a*(s - s_0)
    # - s_0 = 0
    # - v = 0
    # - Algebra...
    # - s = -v_0^2 / 2 / a
    return (movement_params.jump_boost * movement_params.jump_boost) / 2.0 / \
            movement_params.gravity_slow_rise
