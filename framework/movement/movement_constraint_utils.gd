# A collection of utility functions for calculating state related to MovementConstraints.
class_name MovementConstraintUtils

const MovementConstraint := preload("res://framework/movement/models/movement_constraint.gd")

# FIXME: D: Tweak this.
const MIN_MAX_VELOCITY_X_OFFSET := 0.01

static func create_terminal_constraints(origin_surface: Surface, origin_position: Vector2, \
        destination_surface: Surface, destination_position: Vector2, \
        movement_params: MovementParams, velocity_start: Vector2, \
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
            velocity_start, can_hold_jump_button, null, null)
    var is_destination_valid := update_constraint(destination, origin, null, origin, \
            movement_params, velocity_start, can_hold_jump_button, null, null)
    
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
            origin_constraint, movement_params, vertical_step.velocity_step_start, \
            vertical_step.can_hold_jump_button, vertical_step, null)
    var is_b_valid := update_constraint(constraint_b, previous_constraint, null, \
            origin_constraint, movement_params, vertical_step.velocity_step_start, \
            vertical_step.can_hold_jump_button, vertical_step, null)
    
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
        velocity_start_origin: Vector2, can_hold_jump_button_at_origin: bool, \
        vertical_step: MovementVertCalcStep, \
        additional_high_constraint: MovementConstraint) -> bool:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.

    # Previous and next constraints and vertical_step should be provided when updating intermediate constraints.
    assert(previous_constraint != null or constraint.is_origin)
    assert(next_constraint != null or constraint.is_destination)
    assert(vertical_step != null or constraint.is_destination or constraint.is_origin)

    # additional_high_constraint should only ever be provided for the destination, and then only
    # when we're doing backtracking for a new jump-height.
    assert(additional_high_constraint == null or constraint.is_destination)
    assert(vertical_step != null or additional_high_constraint == null)

    var horizontal_movement_sign := \
            calculate_horizontal_movement_sign(constraint, previous_constraint, next_constraint)
    
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
        var position := constraint.position
        var previous_position := previous_constraint.position
        var displacement := position - previous_position
        
        # Check whether the vertical displacement is possible.
        if displacement.y < -movement_params.max_upward_jump_distance:
            return false
        
        if constraint.is_destination:
            # For the destination constraint, we need to calculate time_to_release_jump. All other
            # constraints can re-use this information from the vertical_step.

            var time_to_release_jump: float

            # We consider different parameters if we are starting a new movement calculation vs
            # backtracking to consider a new jump height.
            var constraint_to_calculate_jump_release_time_for: MovementConstraint
            if vertical_step == null:
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
                return false
            assert(time_to_pass_through_constraint_ignoring_others > 0.0)

            var displacement_from_origin: Vector2 = \
                    constraint_to_calculate_jump_release_time_for.position - origin_position
            time_to_release_jump = VerticalMovementUtils.calculate_time_to_release_jump_button( \
                    movement_params, time_to_pass_through_constraint_ignoring_others, \
                    displacement_from_origin)
            # If time_to_pass_through_constraint_ignoring_others was valid, then this should also
            # be valid.
            assert(time_to_release_jump != INF)

            if vertical_step != null:
                # We are backtracking to consider a new jump height.
                # The destination jump-release time should account for both:
                # - the time needed to reach any previous jump-heights before this current round of
                #   jump-height backtracking (vertical_step.time_instruction_end),
                # - and the time needed to reach this new previously-out-of-reach constraint
                #   (time_to_release_jump for the new constraint).
                time_to_release_jump = \
                        max(vertical_step.time_instruction_end, time_to_release_jump)
                
                time_passing_through = \
                        VerticalMovementUtils.calculate_time_for_passing_through_constraint( \
                                movement_params, vertical_step, constraint, \
                                vertical_step.time_step_end)
            else:
                # We are starting a new movement calculation (not backtracking to consider a new
                # jump height).
                time_passing_through = time_to_pass_through_constraint_ignoring_others

        else:
            # This is an intermediate constraint (not the origin or destination).
            time_passing_through = \
                    VerticalMovementUtils.calculate_time_for_passing_through_constraint( \
                            movement_params, vertical_step, constraint, \
                            previous_constraint.time_passing_through)
            
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
        var min_and_max_velocity_at_step_end := calculate_min_and_max_velocity_at_end_of_interval( \
                previous_position.x, position.x, duration, \
                previous_constraint.min_velocity_x, previous_constraint.max_velocity_x, \
                movement_params.max_horizontal_speed_default, \
                movement_params.in_air_horizontal_acceleration, \
                horizontal_movement_sign)
        if min_and_max_velocity_at_step_end.empty():
            return false
        
        min_velocity_x = min_and_max_velocity_at_step_end[0]
        max_velocity_x = min_and_max_velocity_at_step_end[1]
        
        if constraint.is_destination:
            # Initialize the destination constraint's actual velocity to match whichever min/max
            # value yields the least overall movement.
            actual_velocity_x = \
                    constraint.min_velocity_x if horizontal_movement_sign > 0 else \
                    constraint.max_velocity_x
        else:
            # actual_velocity_x is calculated in a back-to-front pass when calculating the
            # horizontal steps.
            actual_velocity_x = INF
    
    constraint.horizontal_movement_sign = horizontal_movement_sign
    constraint.time_passing_through = time_passing_through
    constraint.min_velocity_x = min_velocity_x
    constraint.max_velocity_x = max_velocity_x
    constraint.actual_velocity_x = actual_velocity_x
    
    return true

static func calculate_horizontal_movement_sign(constraint: MovementConstraint, \
        previous_constraint: MovementConstraint, next_constraint: MovementConstraint) -> int:
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
    
    assert(horizontal_movement_sign_from_surface == horizontal_movement_sign_from_displacement or \
            (is_origin and displacement_sign == 0))

    return horizontal_movement_sign_from_surface

# The given parameters represent the horizontal motion of a single step.
# 
# A Vector2 is returned:
# - The x property represents the min velocity.
# - The y property represents the max velocity.
static func calculate_min_and_max_velocity_at_end_of_interval(s_0: float, s: float, t: float, \
        v_0_min_from_prev_constraint: float, v_0_max_from_prev_constraint: float, \
        speed_max: float, a_magnitude: float, horizontal_movement_sign: int) -> Array:
    # FIXME: LEFT OFF HERE: -----------------------------------------------------A
    # - This function is broken.
    # - Need to support accelerating at the start of the step, and coasting at the end.
    # - Need to also take another look at how we ensure that horizontal movement through the
    #   constraint happens in the correct direction.
    # - Need to carry-over some logic from calculate_horizontal_step...
    # 
    
    var displacement := s - s_0
    
    if horizontal_movement_sign < 0:
        # Swap some params, so that we can simplify the calculations to assume one direction.
        var swap := s_0
        s_0 = s
        s = swap
        swap = v_0_min_from_prev_constraint
        v_0_min_from_prev_constraint = -v_0_max_from_prev_constraint
        v_0_max_from_prev_constraint = -swap
        displacement = -displacement
    
    var d_squared: float
    var duration_to_hold_move_sideways: float
    var min_v_0_that_can_reach_target: float
    var max_v_0_that_can_reach_target: float
    var v_0_min: float
    var v_0_max: float
    
    # Calculate the max-possible end x velocity.
    # - First, try using a forward acceleration.
    # - Then, try a backward acceleration, if forward didn't work.
    var v_max: float
    for a in [a_magnitude, -a_magnitude]:
        # The minimum possible v_0 will yield the maximum possible v. This is because if we
        # accelerate over the entire step, we will have the max possible v, and if we start with a
        # lower v_0, we are more likely to accelerate over more of the step.
        # From a basic equation of motion:
        #    s = s_0 + v_0*t + 1/2*a*t^2
        #    Algebra...
        #    v_0 = (s - s_0)/t - 1/2*a*t
        min_v_0_that_can_reach_target = displacement / t - 0.5 * a * t
        # The mimimum possible v_0 is dependent on both the duration of the current step and the
        # minimum possible step-end v_0 from the previous step.
        v_0_min = max(min_v_0_that_can_reach_target, v_0_min_from_prev_constraint)
        
        # - There are two parts:
        #   - Part 1: Coast at v_0 until we need to start accelerating.
        #   - Part 2: Constant acceleration from v_0 to v_1.
        #   - The longer part 1 is, the more we can accelerate during part 2, and the bigger v_1 can
        #     be.
        # Derivation:
        # - Start with basic equations of motion
        # - s_1 = s_0 + v_0*t_1
        # - s_2 = s_1 + v_0*t_2 + 1/2*a*t_2^2
        # - t_total = t_1 + t_2
        # - Do some algebra...
        # - t_2 = sqrt(2 * (s_2 - s_0 - v_0*t_total) / a)
        d_squared = 2 * (s - s_0 - v_0_min * t) / a
        if d_squared < 0:
            # We cannot reach the end with these parameters.
            continue
        duration_to_hold_move_sideways = sqrt(d_squared)
        
        # From a basic equation of motion:
        #    v = v_0 + a*t
        v_max = v_0_min + a * duration_to_hold_move_sideways
    
    # Calculate the min-possible end x velocity.
    # - First, try using a backward acceleration.
    # - Then, try a forward acceleration, if backward didn't work.
    var v_min: float
    for a in [-a_magnitude, a_magnitude]:
        # The maximum possible v_0 will yield the minimum possible v. This is because if we
        # decelerate over the entire step, we will have the min possible v, and if we start with a
        # higher v_0, we are more likely to decelerate over more of the step.
        # From a basic equation of motion:
        #    s = s_0 + v_0*t + 1/2*a*t^2
        #    Algebra...
        #    v_0 = (s - s_0)/t - 1/2*a*t
        max_v_0_that_can_reach_target = displacement / t - 0.5 * a * t
        # The maximum possible v_0 is dependent on both the duration of the current step and the
        # maximum possible step-end v_0 from the previous step.
        v_0_max = min(max_v_0_that_can_reach_target, v_0_max_from_prev_constraint)
        
        # - There are two parts:
        #   - Part 1: Coast at v_0 until we need to start decelerating.
        #   - Part 2: Constant deceleration from v_0 to v_1.
        #   - The longer part 1 is, the more we can decelerate during part 2, and the smaller v_1 can
        #     be.
        # Derivation:
        # - Start with basic equations of motion
        # - s_1 = s_0 + v_0*t_1
        # - s_2 = s_1 + v_0*t_2 + 1/2*a*t_2^2
        # - t_total = t_1 + t_2
        # - Do some algebra...
        # - t_2 = sqrt(2 * (s_2 - s_0 - v_0*t_total) / a)
        d_squared = 2 * (s - s_0 - v_0_max * t) / a
        if d_squared < 0:
            # We cannot reach the end with these parameters.
            continue
        duration_to_hold_move_sideways = sqrt(d_squared)
        
        # From a basic equation of motion:
        #    v = v_0 + a*t
        v_min = v_0_max + a * duration_to_hold_move_sideways
    
    if v_min == INF or v_max == INF:
        # Expect that if one value is invalid, the other should be too.
        assert(v_min == INF and v_max == INF)
        # We cannot reach this constraint from the previous constraint.
        return []
    
    # Correct small floating-point errors around zero.
    if Geometry.are_floats_equal_with_epsilon(v_min, 0.0):
        v_min = 0.0
    if Geometry.are_floats_equal_with_epsilon(v_max, 0.0):
        v_max = 0.0
    
    assert(v_min >= 0.0)
    assert(v_max >= 0.0)
    
    # Add a small offset to the min and max to help with round-off errors.
    v_min += MIN_MAX_VELOCITY_X_OFFSET
    v_max -= MIN_MAX_VELOCITY_X_OFFSET
    
    if v_min > speed_max:
        # We cannot reach this constraint from the previous constraint.
        return []
    
    # Limit max speed.
    v_max = min(v_max, speed_max)
    
    if horizontal_movement_sign > 0:
        return [v_min, v_max]
    else:
        return [-v_max, -v_min]

static func update_neighbors_for_new_constraint(constraint: MovementConstraint, \
        previous_constraint: MovementConstraint, next_constraint: MovementConstraint, \
        global_calc_params: MovementCalcGlobalParams, \
        vertical_step: MovementVertCalcStep) -> bool:
    var origin := global_calc_params.origin_constraint

    if previous_constraint.is_origin:
        # The next constraint is only used for updates to the origin. Each other constraints just
        # depends on their previous constraint.
        var is_valid := update_constraint(previous_constraint, null, constraint, origin, \
                global_calc_params.movement_params, origin.velocity_start, \
                vertical_step.can_hold_jump_button, vertical_step, null)
        if !is_valid:
            return false
    
    # The next constraint is only used for updates to the origin. Each other constraints just
    # depends on their previous constraint.
    return update_constraint(next_constraint, constraint, null, origin, \
            global_calc_params.movement_params, origin.velocity_start, \
            vertical_step.can_hold_jump_button, vertical_step, null)

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
