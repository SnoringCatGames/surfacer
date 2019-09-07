# A collection of utility functions for calculating state related to MovementConstraints.
class_name MovementConstraintUtils

const MovementConstraint := preload("res://framework/movement/models/movement_constraint.gd")

# FIXME: D: Tweak this.
const MIN_MAX_VELOCITY_X_OFFSET := 0.01

static func create_terminal_constraints(origin_surface: Surface, origin_position: Vector2, \
        destination_surface: Surface, destination_position: Vector2, \
        movement_params: MovementParams, constraint_offset: Vector2, velocity_start: Vector2, \
        can_hold_jump_button: bool) -> Array:
    var origin_passing_vertically := \
            origin_surface.normal.x == 0 if origin_surface != null else true
    var destination_passing_vertically := \
            destination_surface.normal.x == 0 if destination_surface != null else true
    
    var origin := MovementConstraint.new( \
            origin_surface, origin_position, origin_passing_vertically, false)
    var destination := MovementConstraint.new( \
            destination_surface, destination_position, destination_passing_vertically, false)

    origin.is_origin = true
    destination.is_destination = true
    
    var is_origin_valid := update_constraint(origin, null, destination, origin, movement_params, \
            constraint_offset, velocity_start, can_hold_jump_button, null, null)
    var is_destination_valid := update_constraint(destination, origin, null, origin, \
            movement_params, constraint_offset, velocity_start, can_hold_jump_button, null, null)
    
    if is_origin_valid and is_destination_valid:
        return [origin, destination]
    else:
        return []

static func calculate_constraints_around_surface(movement_params: MovementParams, \
        vertical_step: MovementVertCalcStep, previous_constraint: MovementConstraint, \
        origin_constraint: MovementConstraint, colliding_surface: Surface, \
        constraint_offset: Vector2) -> Array:
    var passing_vertically: bool
    var position_a: Vector2
    var position_b: Vector2
    
    # Calculate the positions of each constraint.
    match colliding_surface.side:
        SurfaceSide.FLOOR:
            passing_vertically = true
            # Left end
            position_a = colliding_surface.vertices[0] + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
            # Right end
            position_b = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
        SurfaceSide.CEILING:
            passing_vertically = true
            # Left end
            position_a = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
            # Right end
            position_b = colliding_surface.vertices[0] + \
                    Vector2(constraint_offset.x, constraint_offset.y)
        SurfaceSide.LEFT_WALL:
            passing_vertically = false
            # Top end
            position_a = colliding_surface.vertices[0] + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
            # Bottom end
            position_b = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(constraint_offset.x, constraint_offset.y)
        SurfaceSide.RIGHT_WALL:
            passing_vertically = false
            # Top end
            position_a = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
            # Bottom end
            position_b = colliding_surface.vertices[0] + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
    
    var constraint_a := MovementConstraint.new( \
            colliding_surface, position_a, passing_vertically, true)
    var constraint_b := MovementConstraint.new( \
            colliding_surface, position_b, passing_vertically, false)
    
    var is_a_valid := update_constraint(constraint_a, previous_constraint, null, \
            origin_constraint, movement_params, constraint_offset, \
            vertical_step.velocity_step_start, vertical_step.can_hold_jump_button, vertical_step, \
            null)
    var is_b_valid := update_constraint(constraint_b, previous_constraint, null, \
            origin_constraint, movement_params, constraint_offset, \
            vertical_step.velocity_step_start, vertical_step.can_hold_jump_button, vertical_step, \
            null)
    
    var result := []
    if is_a_valid:
        result.push_back(constraint_a)
    if is_b_valid:
        result.push_back(constraint_b)
    return result

# Returns false if the constraint cannot satisfy the given parameters.
static func update_constraint(constraint: MovementConstraint, \
        previous_constraint: MovementConstraint, next_constraint: MovementConstraint, \
        origin_constraint: MovementConstraint, movement_params: MovementParams, \
        constraint_offset: Vector2, velocity_start_origin: Vector2, \
        can_hold_jump_button_at_origin: bool, vertical_step: MovementVertCalcStep, \
        additional_high_constraint: MovementConstraint) -> bool:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.

    # Previous constraint and vertical_step should be provided when updating intermediate
    # constraints.
    assert(previous_constraint != null or constraint.is_origin)
    assert(vertical_step != null or constraint.is_destination or constraint.is_origin)

    # additional_high_constraint should only ever be provided for the destination, and then only
    # when we're doing backtracking for a new jump-height.
    assert(additional_high_constraint == null or constraint.is_destination)
    assert(vertical_step != null or additional_high_constraint == null)

    assign_horizontal_movement_sign(constraint, previous_constraint, next_constraint)
    
    if constraint.horizontal_movement_sign != \
            constraint.horizontal_movement_sign_from_displacement:
        # This constraint should be skipped, and movement should proceed directly to the next one
        # (but we still need to keep this constraint around long enough to calculate whath that
        # next constraint is).
        constraint.is_fake = true
        constraint.horizontal_movement_sign = constraint.horizontal_movement_sign_from_displacement
        constraint.position = calculate_fake_constraint_position(constraint, constraint_offset)
    
    var time_passing_through: float
    var min_velocity_x: float
    var max_velocity_x: float
    var actual_velocity_x: float

    # Calculate the time that the movement would pass through the constraint, as well as the min
    # and max x-velocity when passing through the constraint.
    if constraint.is_origin:
        time_passing_through = 0.0
        min_velocity_x = velocity_start_origin.x
        max_velocity_x = velocity_start_origin.x
        actual_velocity_x = velocity_start_origin.x
    else:
        var displacement := constraint.position - previous_constraint.position
        
        # Check whether the vertical displacement is possible.
        if displacement.y < -movement_params.max_upward_jump_distance:
            # We can't reach this constraint.
            return false
        
        if constraint.is_destination:
            # For the destination constraint, we need to calculate time_to_release_jump. All other
            # constraints can re-use this information from the vertical_step.

            var time_to_release_jump: float

            # We consider different parameters if we are starting a new movement calculation vs
            # backtracking to consider a new jump height.
            var constraint_to_calculate_jump_release_time_for: MovementConstraint
            if additional_high_constraint == null:
                # We are starting a new movement calculation (not backtracking to consider a new
                # jump height).
                constraint_to_calculate_jump_release_time_for = constraint
            else:
                # We are backtracking to consider a new jump height.
                constraint_to_calculate_jump_release_time_for = additional_high_constraint
            
            # TODO: I should probably refactor these two calls, so we're doing fewer redundant
            #       calculations here.
            
            var origin_position := origin_constraint.position
            
            var time_to_pass_through_constraint_ignoring_others := \
                    VerticalMovementUtils.calculate_time_to_jump_to_constraint(movement_params, \
                            origin_position, \
                            constraint_to_calculate_jump_release_time_for.position, \
                            velocity_start_origin, can_hold_jump_button_at_origin)
            if time_to_pass_through_constraint_ignoring_others == INF:
                # We can't reach this constraint.
                return false
            assert(time_to_pass_through_constraint_ignoring_others > 0.0)
            
            if additional_high_constraint != null:
                # We are backtracking to consider a new jump height.
                # The destination jump time should account for both:
                # - the time needed to reach any previous jump-heights before this current round of
                #   jump-height backtracking (vertical_step.time_instruction_end),
                # - the time needed to reach this new previously-out-of-reach constraint
                #   (time_to_release_jump for the new constraint),
                # - and the time needed to get to the destination from this new constraint.
                
                # TODO: There might be cases that this fails for? We might need to add more time.
                #       Revisit this if we see problems.
                
                var time_to_get_to_destination_from_constraint := \
                        calculate_time_to_reach_destination_from_new_constraint(movement_params, \
                                additional_high_constraint, constraint)
                if time_to_get_to_destination_from_constraint == INF:
                    # We can't reach the destination from this constraint.
                    return false
                time_passing_through = max(vertical_step.time_step_end, \
                        time_to_pass_through_constraint_ignoring_others + \
                                time_to_get_to_destination_from_constraint)
            else:
                time_passing_through = time_to_pass_through_constraint_ignoring_others
            
            var displacement_from_origin: Vector2 = \
                    constraint_to_calculate_jump_release_time_for.position - origin_position
            time_to_release_jump = VerticalMovementUtils.calculate_time_to_release_jump_button( \
                    movement_params, time_passing_through, displacement_from_origin.y)
            # If time_passing_through was valid, then this should also be valid.
            assert(time_to_release_jump != INF)
            
        else:
            # This is an intermediate constraint (not the origin or destination).
            time_passing_through = \
                    VerticalMovementUtils.calculate_time_for_passing_through_constraint( \
                            movement_params, constraint, \
                            previous_constraint.time_passing_through, \
                            vertical_step.position_step_start.y, \
                            vertical_step.time_instruction_end, \
                            vertical_step.position_instruction_end.y, \
                            vertical_step.velocity_instruction_end.y)
            if time_passing_through == INF:
                # We can't reach this constraint from the previous constraint.
                return false
            
            var still_holding_jump_button := \
                    time_passing_through < vertical_step.time_instruction_end
            
            # We can quit early for a few types of constraints.
            if !constraint.passing_vertically and constraint.should_stay_on_min_side and \
                    still_holding_jump_button:
                # Quit early if we are trying to go above a wall, but we already released the jump
                # button.
                return false
            elif !constraint.passing_vertically and !constraint.should_stay_on_min_side and \
                    !still_holding_jump_button:
                # Quit early if we are trying to go below a wall, but we are still holding the jump
                # button.
                return false
            else:
                # We should never hit a floor while still holding the jump button.
                assert(!(constraint.surface.side == SurfaceSide.FLOOR and \
                        still_holding_jump_button))
        
        # Calculate the min and max velocity for movement through the constraint.
        var duration := time_passing_through - previous_constraint.time_passing_through
        var min_and_max_velocity_at_step_end := \
                calculate_min_and_max_x_velocity_at_end_of_interval(displacement.x, duration, \
                        previous_constraint.min_velocity_x, previous_constraint.max_velocity_x, \
                        movement_params.max_horizontal_speed_default, \
                        movement_params.in_air_horizontal_acceleration, \
                        constraint.horizontal_movement_sign)
        if min_and_max_velocity_at_step_end.empty():
            return false
        
        min_velocity_x = min_and_max_velocity_at_step_end[0]
        max_velocity_x = min_and_max_velocity_at_step_end[1]
        
        if constraint.is_destination:
            # Initialize the destination constraint's actual velocity to match whichever min/max
            # value yields the least overall movement.
            actual_velocity_x = min_velocity_x if constraint.horizontal_movement_sign > 0 \
                    else max_velocity_x
        else:
            # actual_velocity_x is calculated in a back-to-front pass when calculating the
            # horizontal steps.
            actual_velocity_x = INF
    
    constraint.time_passing_through = time_passing_through
    constraint.min_velocity_x = min_velocity_x
    constraint.max_velocity_x = max_velocity_x
    constraint.actual_velocity_x = actual_velocity_x
    
    return true

static func calculate_fake_constraint_position(constraint: MovementConstraint, \
        constraint_offset: Vector2) -> Vector2:
    assert(constraint.surface.side == SurfaceSide.FLOOR or \
            constraint.surface.side == SurfaceSide.CEILING)
    
    var actual_vs_test_margin_diff := MovementCalcGlobalParams.EDGE_MOVEMENT_ACTUAL_MARGIN - \
            MovementCalcGlobalParams.EDGE_MOVEMENT_TEST_MARGIN - 0.001
    var player_half_height := \
            constraint_offset.y - MovementCalcGlobalParams.EDGE_MOVEMENT_ACTUAL_MARGIN
    
    var position := constraint.position
    
    # Undo the normal margin, and align the player closer to the surface.
    position.x += actual_vs_test_margin_diff if constraint.should_stay_on_min_side else \
            -actual_vs_test_margin_diff
    position.y += actual_vs_test_margin_diff if SurfaceSide.FLOOR else -actual_vs_test_margin_diff
    
    # Align the player so that they are straddling the edge of the surface.
    position.y += player_half_height if SurfaceSide.FLOOR else -player_half_height
    
    return position

# This only considers the time to move horizontally and the time to fall; this does not consider
# the time to rise from the new constraint to the destination.
# - We don't consider rise time, since that would require knowing more information around when the
#   jump button is released and whether it could still be held.
# - For horizontal movement time, we don't need to know about vertical velocity or the jump button.
# - For fall time, we can assume that vertical velocity will be zero when passing through this new
#   constraint (since it should be the highest point we reach in the jump).
static func calculate_time_to_reach_destination_from_new_constraint( \
        movement_params: MovementParams, new_constraint: MovementConstraint, \
        destination: MovementConstraint) -> float:
    var displacement := destination.position - new_constraint.position

    var velocity_x_at_new_constraint: float
    var acceleration: float
    if displacement.x > 0:
        velocity_x_at_new_constraint = new_constraint.max_velocity_x
        acceleration = movement_params.in_air_horizontal_acceleration
    else:
        velocity_x_at_new_constraint = new_constraint.min_velocity_x
        acceleration = -movement_params.in_air_horizontal_acceleration
    
    var time_to_reach_horizontal_displacement := \
            MovementUtils.calculate_min_time_to_reach_displacement(displacement.x, \
                    velocity_x_at_new_constraint, movement_params.max_horizontal_speed_default, \
                    acceleration)

    var time_to_reach_fall_displacement: float
    if displacement.y > 0:
        time_to_reach_fall_displacement = Geometry.calculate_movement_duration( \
                displacement.y, 0.0, movement_params.gravity_fast_fall, true, 0.0, true)
    else:
        time_to_reach_fall_displacement = 0.0
    
    return max(time_to_reach_horizontal_displacement, time_to_reach_fall_displacement)

static func assign_horizontal_movement_sign(constraint: MovementConstraint, \
        previous_constraint: MovementConstraint, next_constraint: MovementConstraint) -> void:
    assert(constraint.surface != null or constraint.is_origin or constraint.is_destination)
    assert(previous_constraint != null or constraint.is_origin)
    assert(next_constraint != null or !constraint.is_origin)
    
    var surface := constraint.surface
    var displacement := constraint.position - previous_constraint.position if \
            previous_constraint != null else next_constraint.position - constraint.position
    var neighbor_horizontal_movement_sign := previous_constraint.horizontal_movement_sign if \
            previous_constraint != null else next_constraint.horizontal_movement_sign
    var is_origin := constraint.is_origin
    var is_destination := constraint.is_destination

    var displacement_sign := \
            0 if Geometry.are_floats_equal_with_epsilon(displacement.x, 0.0, 0.1) else \
            (1 if displacement.x > 0 else \
            -1)
    
    var horizontal_movement_sign_from_displacement := \
            -1 if displacement_sign == -1 else \
            (1 if displacement_sign == 1 else \
            # For straight-vertical steps, if there was any horizontal movement through the
            # previous, then we're going to need to backtrack in the opposition direction to reach
            # the destination.
            (neighbor_horizontal_movement_sign if neighbor_horizontal_movement_sign != INF else \
            # For straight vertical steps from the origin, we don't have much to go off of for
            # picking the horizontal movement direction, so just default to rightward for now.
            1))

    var horizontal_movement_sign_from_surface: int
    if is_origin:
        horizontal_movement_sign_from_surface = \
                1 if surface != null and surface.side == SurfaceSide.LEFT_WALL else \
                (-1 if surface != null and surface.side == SurfaceSide.RIGHT_WALL else \
                horizontal_movement_sign_from_displacement)
    elif is_destination:
        horizontal_movement_sign_from_surface = \
                -1 if surface != null and surface.side == SurfaceSide.LEFT_WALL else \
                (1 if surface != null and surface.side == SurfaceSide.RIGHT_WALL else \
                horizontal_movement_sign_from_displacement)
    else:
        horizontal_movement_sign_from_surface = \
                -1 if surface.side == SurfaceSide.LEFT_WALL else \
                (1 if surface.side == SurfaceSide.RIGHT_WALL else \
                (-1 if constraint.should_stay_on_min_side else 1))

    constraint.horizontal_movement_sign = horizontal_movement_sign_from_surface
    constraint.horizontal_movement_sign_from_displacement = horizontal_movement_sign_from_displacement

# The given parameters represent the horizontal motion of a single step.
# 
# A Vector2 is returned:
# - The x property represents the min velocity.
# - The y property represents the max velocity.
static func calculate_min_and_max_x_velocity_at_end_of_interval(displacement: float, \
        duration: float, v_0_min_from_prev_constraint: float, \
        v_0_max_from_prev_constraint: float, speed_max: float, a_magnitude: float, \
        horizontal_movement_sign: int) -> Array:
    ### Calculate more tightly-bounded min/max start velocity values, according to both the
    ### duration of the current step and the given min/max values from the previous constraint.

    # Accelerating in a positive direction over the entire step, corresponds to a lower bound on
    # the start velocity, and accelerating in a negative direction over the entire step,
    # corresponds to an upper bound on the start velocity.
    # 
    # Derivation:
    # - From a basic equation of motion:
    #   s = s_0 + v_0*t + 1/2*a*t^2
    # - Algebra...
    #   v_0 = (s - s_0)/t - 1/2*a*t
    var min_v_0_that_can_reach_target := \
            displacement / duration - 0.5 * a_magnitude * duration
    var max_v_0_that_can_reach_target := \
            displacement / duration + 0.5 * a_magnitude * duration
    
    # From a basic equation of motion:
    #    v = v_0 + a*t
    var min_v_0_that_can_reach_max_velocity := speed_max - a_magnitude * duration
    var max_v_0_that_can_reach_min_velocity := -speed_max + a_magnitude * duration
    
    if min_v_0_that_can_reach_target > min_v_0_that_can_reach_max_velocity:
        var acceleration := a_magnitude
        var v_1 := speed_max
        min_v_0_that_can_reach_target = \
                calculate_min_v_0_with_v_1_limit(displacement, duration, v_1, acceleration, true)
        if min_v_0_that_can_reach_target == INF:
            return []
    
    if max_v_0_that_can_reach_target < max_v_0_that_can_reach_min_velocity:
        var acceleration := -a_magnitude
        var v_1 := -speed_max
        max_v_0_that_can_reach_target = \
                calculate_min_v_0_with_v_1_limit(displacement, duration, v_1, acceleration, false)
        if max_v_0_that_can_reach_target == INF:
            return []
    
    # The min and max possible v_0 are dependent on both the duration of the current step and the
    # min and max possible step-end v_0 from the previous step, respectively.
    var v_0_min := max(min_v_0_that_can_reach_target, v_0_min_from_prev_constraint)
    var v_0_max := min(max_v_0_that_can_reach_target, v_0_max_from_prev_constraint)
    
    if v_0_min > v_0_max:
        # Neither direction of acceleration will work with the given min/max start velocities from
        # the previous step.
        return []

    ### Calculate min/max end velocities according to the min/max start velocities.

    # We could need to either accelerate at the start or the end of the interval, and in a forward
    # or backward direction, in order to hit the min and max end velocity. So we consider all four
    # combinations, and only keep the best/valid results.
    # 
    # Some notes about these calculations:
    # - Min and max start velocities correspond to max and min end velocities, respectively.
    # - If negative acceleration can be used during this interval, then we want to accelerate at
    #   the start of the interval to find the max end velocity and accelerate at the end of the
    #   interval to find the min end velocity.
    # - If positive acceleration can be used during this interval, then we want to accelerate at
    #   the end of the interval to find the min end velocity and accelerate at the start of the
    #   interval to find the max end velocity.
    # - All of the above is true regardless of the direction of displacement for the interval.

    # FIXME: If I see any problems from this logic, then just calculate the other four cases too,
    #        and use the best valid ones from the whole set of 8.
    
    var v_0: float
    var acceleration: float
    var should_accelerate_at_start: bool
    var should_return_min_result: bool

    v_0 = v_0_max
    acceleration = a_magnitude
    should_accelerate_at_start = true
    should_return_min_result = true
    var v_min_pos_acc_at_start := solve_for_end_velocity(displacement, v_0, acceleration, \
            duration, speed_max, should_accelerate_at_start, should_return_min_result)

    v_0 = v_0_min
    acceleration = -a_magnitude
    should_accelerate_at_start = true
    should_return_min_result = false
    var v_max_neg_acc_at_start := solve_for_end_velocity(displacement, v_0, acceleration, \
            duration, speed_max, should_accelerate_at_start, should_return_min_result)

    v_0 = v_0_min
    acceleration = a_magnitude
    should_accelerate_at_start = false
    should_return_min_result = false
    var v_max_pos_acc_at_end := solve_for_end_velocity(displacement, v_0, acceleration, \
            duration, speed_max, should_accelerate_at_start, should_return_min_result)

    v_0 = v_0_max
    acceleration = -a_magnitude
    should_accelerate_at_start = false
    should_return_min_result = true
    var v_min_neg_acc_at_end := solve_for_end_velocity(displacement, v_0, acceleration, \
            duration, speed_max, should_accelerate_at_start, should_return_min_result)

    # Use the more extreme of the possible min/max values we calculated for positive/negative
    # acceleration at the start/end.
    var v_max := \
            max(v_max_neg_acc_at_start, v_max_pos_acc_at_end) if \
                    v_max_neg_acc_at_start != INF and v_max_pos_acc_at_end != INF else \
            (v_max_neg_acc_at_start if v_max_neg_acc_at_start != INF else \
            v_max_pos_acc_at_end)
    var v_min := \
            min(v_min_pos_acc_at_start, v_min_neg_acc_at_end) if \
                    v_min_pos_acc_at_start != INF and v_min_neg_acc_at_end != INF else \
            (v_min_pos_acc_at_start if v_min_pos_acc_at_start != INF else \
            v_min_neg_acc_at_end)

    # If we found valid v_0_min/v_0_max values, then there must be valid corresponding v_min/v_max
    # values.
    assert(v_max != INF)
    assert(v_min != INF)
    assert(v_max >= v_min)
    
    # Correct small floating-point errors around zero.
    if Geometry.are_floats_equal_with_epsilon(v_min, 0.0):
        v_min = 0.0
    if Geometry.are_floats_equal_with_epsilon(v_max, 0.0):
        v_max = 0.0

    if (horizontal_movement_sign > 0 and v_max < 0) or \
        (horizontal_movement_sign < 0 and v_min > 0):
        # We cannot reach this constraint with the needed movement direction.
        return []

    # Add a small offset to the min and max to help with round-off errors.
    if horizontal_movement_sign > 0:
        v_min += MIN_MAX_VELOCITY_X_OFFSET
        v_max -= MIN_MAX_VELOCITY_X_OFFSET
    else:
        v_min -= MIN_MAX_VELOCITY_X_OFFSET
        v_max += MIN_MAX_VELOCITY_X_OFFSET

    # Limit velocity to the expected movement direction for this constraint.
    if horizontal_movement_sign > 0:
        v_min = max(v_min, 0.0)
    else:
        v_max = min(v_max, 0.0)
    
    # Limit max speed.
    if horizontal_movement_sign > 0:
        if v_min > speed_max:
            # We cannot reach this constraint from the previous constraint.
            return []
        v_max = min(v_max, speed_max)
    else:
        if v_max < -speed_max:
            # We cannot reach this constraint from the previous constraint.
            return []
        v_min = max(v_min, -speed_max)

    return [v_min, v_max]

# Accelerating over the whole interval would result in an end velocity that exceeds the max speed.
# So instead, we assume a 2-part movement profile with constant acceleration in the first part and
# constant (max-speed) velocity in the second part. This 2-part movement should correspond to the
# actual limit on v_0.
static func calculate_min_v_0_with_v_1_limit(displacement: float, duration: float, v_1: float, \
        acceleration: float, should_return_min_result: bool) -> float:
    # Derivation:
    # - From basic equations of motion:
    #   - v_1 = v_0 + a*t_0
    #   - s_2 = s_1 + v_1*t_1
    #   - v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
    #   - t_total = t_0 + t_1
    #   - diplacement = s_2 - s_0
    # - Do some algebra...
    #   - 0 = displacement*a/v_1 + 1/2*v_1 - a*t_total - v_0 + 1/2/v_1*v_0^2
    # - Apply quadratic formula to solve for v_1.
    
    var a := 0.5 / v_1
    var b := -1
    var c := displacement * acceleration / v_1 + 0.5 * v_1 - acceleration * duration
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # There is no start velocity that can satisfy these parameters.
        return INF
    
    var discriminant_sqrt := sqrt(discriminant)
    var result_1 := (-b + discriminant_sqrt) / 2.0 / a
    var result_2 := (-b - discriminant_sqrt) / 2.0 / a
    
    # From a basic equation of motion:
    #    v = v_0 + a*t
    var t_result_1 := (v_1 - result_1) / acceleration
    var t_result_2 := (v_1 - result_2) / acceleration
    
    # The results are invalid if they correspond to imaginary negative durations.
    var is_result_1_valid := (t_result_1 >= 0 and t_result_1 <= duration)
    var is_result_2_valid := (t_result_2 >= 0 and t_result_2 <= duration)
    
    if !is_result_1_valid and !is_result_2_valid:
        # There is no start velocity that can satisfy these parameters.
        return INF
    elif !is_result_1_valid:
        return result_2
    elif !is_result_2_valid:
        return result_1
    elif should_return_min_result:
        return min(result_1, result_2)
    else:
        return max(result_1, result_2)

static func solve_for_end_velocity(displacement: float, v_0: float, acceleration: float, \
        duration: float, speed_max: float, should_accelerate_at_start: bool, \
        should_return_min_result: bool) -> float:
    var acceleration_sign := 1 if acceleration >= 0 else -1
    var max_speed_end_velocity := speed_max * acceleration_sign
    
    var a: float
    var b: float
    var c: float
    
    # FIXME: -------------- REMOVE: DEBUGGING
#    duration = 1.3
    
    if should_accelerate_at_start:
        # Try accelerating at the start of the step.
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant acceleration from v_0 to v_1.
        #   - Part 2: Coast at v_1 until we reach the destination.
        # - Start with basic equations of motion:
        #   - v_1 = v_0 + a*t_0
        #   - s_2 = s_1 + v_1*t_1
        #   - v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
        #   - t_total = t_0 + t_1
        # - Do some algebra...
        #   - 0 = 2*a*(s_2 - s_0) + v_0^2 - 2*(a*t_total + v_0)*v_1 + v_1^2
        # - Apply quadratic formula to solve for v_1.
        a = 1
        b = -2 * (acceleration * duration + v_0)
        c = 2 * acceleration * displacement + v_0 * v_0
    else:
        # Try accelerating at the end of the step.
        
        # From a basic equation of motion:
        #    v = v_0 + a*t
        var time_to_max_speed := (max_speed_end_velocity - v_0) / acceleration
        
        # From a basic equation of motion:
        #    s = s_0 + v_0*t + 1/2*a*t^2
        var displacement_during_acceleration_to_max_speed := v_0 * time_to_max_speed + \
                0.5 * acceleration * time_to_max_speed * time_to_max_speed
        
        var duration_of_constant_velocity := duration - time_to_max_speed
        var displacement_with_constant_v_only_at_start := \
                displacement_during_acceleration_to_max_speed + \
                duration_of_constant_velocity * v_0
        var displacement_with_constant_v_only_at_end := \
                displacement_during_acceleration_to_max_speed + \
                duration_of_constant_velocity * max_speed_end_velocity
        
        var is_time_to_max_speed_valid := time_to_max_speed <= duration
        var is_displacement_to_max_speed_with_constant_v_only_at_start_valid := \
                (acceleration_sign > 0 and \
                displacement_with_constant_v_only_at_start < displacement) or \
                (acceleration_sign < 0 and \
                displacement_with_constant_v_only_at_start > displacement)
        
        if is_time_to_max_speed_valid and \
                is_displacement_to_max_speed_with_constant_v_only_at_start_valid:
            # Use a 3-part approach to solve for end velocity. This assumes that some time will be
            # spent at max speed. So the three parts of the movement profile are:
            # 1. Start with constant velocity,
            # 2. Then use contant acceleration until we reach max speed,
            # 3. Then use constant velocity (at max speed) until we reach the end position.
            # 
            # However, we don't need to calculate the durations of those three steps here. Instead,
            # we can just calculate whether putting all the extra time at the start would cause us
            # to under-shoot the end position, and whether putting all the extra time at the end
            # would cause us to over-shoot the end position. If both of those are true, then this
            # is a valid movement profile, and we can reach the end position with a max-speed end
            # velocity.
            
            var is_displacement_to_max_speed_with_constant_v_only_at_end_valid := \
                    (acceleration_sign > 0 and \
                    displacement_with_constant_v_only_at_end > displacement) or \
                    (acceleration_sign < 0 and \
                    displacement_with_constant_v_only_at_end < displacement)
            
            if is_displacement_to_max_speed_with_constant_v_only_at_start_valid and \
                    is_displacement_to_max_speed_with_constant_v_only_at_end_valid:
                # The movement can satisfy these params by accelerating to max speed somewhere
                # between as early and as late as possible.
                return max_speed_end_velocity
            else:
                # The movement can't satisfy these params.
                return INF
        else:
            # Use a 2-part approach to solve for end velocity. This assumes that no time will be
            # spent at max speed (and we probably won't reach max speed at all). So the only two
            # parts of the movement profile are:
            # 1. Start with constrant velocity,
            # 2. Then use constant acceleration until we reach the end position.
            # 
            # Derivation:
            # - Start with basic equations of motion:
            #   - s_1 = s_0 + v_0*t_0
            #   - v_1 = v_0 + a*t_1
            #   - v_1^2 = v_0^2 + 2*a*(s_2 - s_1)
            #   - t_total = t_0 + t_1
            # - Do some algebra...
            #   - 0 = 2*a*(s_2 - s_0 - t_total*v_0) - v_0^2 + 2*v_0*v_1 - v_1^2
            # - Apply quadratic formula to solve for v_1.
            a = -1
            b = 2 * v_0
            c = 2 * acceleration * (displacement - duration * v_0) - v_0 * v_0
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # There is no end velocity that can satisfy these parameters.
        return INF
    
    var discriminant_sqrt := sqrt(discriminant)
    var result_1 := (-b + discriminant_sqrt) / 2.0 / a
    var result_2 := (-b - discriminant_sqrt) / 2.0 / a
    
    # Fix small round-off errors near max-speed values.
    if Geometry.are_floats_equal_with_epsilon(result_1, max_speed_end_velocity, 0.01):
        result_1 = max_speed_end_velocity
    if Geometry.are_floats_equal_with_epsilon(result_2, max_speed_end_velocity, 0.01):
        result_2 = max_speed_end_velocity
    
    # From a basic equation of motion:
    #    v = v_0 + a*t
    var t_result_1 := (result_1 - v_0) / acceleration
    var t_result_2 := (result_2 - v_0) / acceleration
    
    ###########################################
    # FIXME: --------------- REMOVE: DEBUGGING
    var disp_result_1_foo := v_0*t_result_1 + 0.5*acceleration*t_result_1*t_result_1
    var disp_result_1_bar := result_1*(duration-t_result_1)
    var disp_result_1_total := disp_result_1_foo + disp_result_1_bar
    var disp_result_2_foo := v_0*t_result_2 + 0.5*acceleration*t_result_2*t_result_2
    var disp_result_2_bar := result_2*(duration-t_result_2)
    var disp_result_2_total := disp_result_2_foo + disp_result_2_bar
    ###########################################
    
    # The results are invalid if they correspond to imaginary negative durations or if they exceed
    # max speed.
    var is_result_1_valid := (t_result_1 >= 0 and t_result_1 <= duration) and \
            (abs(result_1) < speed_max)
    var is_result_2_valid := (t_result_2 >= 0 and t_result_2 <= duration) and \
            (abs(result_2) < speed_max)
    
    if !is_result_1_valid and !is_result_2_valid:
        # There is no end velocity that can satisfy these parameters.
        return INF
    elif !is_result_1_valid:
        return result_2
    elif !is_result_2_valid:
        return result_1
    elif should_return_min_result:
        return min(result_1, result_2)
    else:
        return max(result_1, result_2)

static func update_neighbors_for_new_constraint(constraint: MovementConstraint, \
        previous_constraint: MovementConstraint, next_constraint: MovementConstraint, \
        global_calc_params: MovementCalcGlobalParams, \
        vertical_step: MovementVertCalcStep) -> bool:
    var origin := global_calc_params.origin_constraint
    
    if previous_constraint.is_origin:
        # The next constraint is only used for updates to the origin. Each other constraints just
        # depends on their previous constraint.
        var is_valid := update_constraint(previous_constraint, null, constraint, origin, \
                global_calc_params.movement_params, global_calc_params.constraint_offset, \
                vertical_step.velocity_step_start, vertical_step.can_hold_jump_button, \
                vertical_step, null)
        if !is_valid:
            return false
    
    # The next constraint is only used for updates to the origin. Each other constraints just
    # depends on their previous constraint.
    return update_constraint(next_constraint, constraint, null, origin, \
            global_calc_params.movement_params, global_calc_params.constraint_offset, \
            vertical_step.velocity_step_start, vertical_step.can_hold_jump_button, vertical_step, \
            null)

static func copy_constraint(original: MovementConstraint) -> MovementConstraint:
    var copy := MovementConstraint.new(original.surface, original.position, \
            original.passing_vertically, original.should_stay_on_min_side)
    copy.horizontal_movement_sign = original.horizontal_movement_sign
    copy.time_passing_through = original.time_passing_through
    copy.min_velocity_x = original.min_velocity_x
    copy.max_velocity_x = original.max_velocity_x
    copy.actual_velocity_x = original.actual_velocity_x
    copy.is_origin = original.is_origin
    copy.is_destination = original.is_destination
    return copy
