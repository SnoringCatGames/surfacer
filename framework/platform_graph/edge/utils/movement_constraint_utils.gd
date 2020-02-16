# A collection of utility functions for calculating state related to MovementConstraints.
class_name MovementConstraintUtils

const MovementConstraint := preload("res://framework/platform_graph/edge/calculation_models/movement_constraint.gd")

# FIXME: D: Tweak this.
const MIN_MAX_VELOCITY_X_OFFSET := 0.01# FIXME: ------------------------

# FIXME: A: Replace the hard-coded usage of a max-speed ratio with a smarter x-velocity.
const CALCULATE_TIME_TO_REACH_DESTINATION_FROM_NEW_CONSTRAINT_V_X_MAX_SPEED_MULTIPLIER := 0.5

static func create_terminal_constraints(origin_surface: Surface, origin_position: Vector2, \
        destination_surface: Surface, destination_position: Vector2, \
        movement_params: MovementParams, can_hold_jump_button: bool, \
        velocity_start := Vector2.INF, returns_invalid_constraints := false) -> Array:
    assert(origin_surface != null or velocity_start != Vector2.INF)
    if velocity_start == Vector2.INF:
        velocity_start = movement_params.get_jump_initial_velocity(origin_surface.side)
    
    var origin_passing_vertically := \
            origin_surface.normal.x == 0 if origin_surface != null else true
    var destination_passing_vertically := \
            destination_surface.normal.x == 0 if destination_surface != null else true
    
    var origin := MovementConstraint.new(origin_surface, origin_position, \
            origin_passing_vertically, false, null, null)
    var destination := MovementConstraint.new(destination_surface, destination_position, \
            destination_passing_vertically, false, null, null)
    
    origin.is_origin = true
    origin.next_constraint = destination
    destination.is_destination = true
    destination.previous_constraint = origin
    
    # FIXME: B: Consider adding support for specifying required end x-velocity (and y direction)?
    #           For hitting walls.
    
    update_constraint(origin, origin, movement_params, velocity_start, can_hold_jump_button, \
            null, Vector2.INF)
    update_constraint(destination, origin, movement_params, velocity_start, can_hold_jump_button, \
            null, Vector2.INF)
    
    if (origin.is_valid and destination.is_valid) or returns_invalid_constraints:
        return [origin, destination]
    else:
        return []

# Assuming movement would otherwise collide with the given surface, this calculates positions along
# the edges of the surface that the movement could pass through in order to go around the surface.
static func calculate_constraints_around_surface(movement_params: MovementParams, \
        vertical_step: MovementVertCalcStep, previous_constraint: MovementConstraint, \
        next_constraint: MovementConstraint, origin_constraint: MovementConstraint, \
        destination_constraint: MovementConstraint, colliding_surface: Surface, \
        constraint_offset: Vector2) -> Array:
    var passing_vertically: bool
    var should_stay_on_min_side_a: bool
    var should_stay_on_min_side_b: bool
    var position_a := Vector2.INF
    var position_b := Vector2.INF
    
    # Calculate the positions of each constraint.
    match colliding_surface.side:
        SurfaceSide.FLOOR:
            passing_vertically = true
            should_stay_on_min_side_a = true
            should_stay_on_min_side_b = false
            # Left end (counter-clockwise end).
            position_a = colliding_surface.first_point + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
            # Right end (clockwise end).
            position_b = colliding_surface.last_point + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
        SurfaceSide.CEILING:
            passing_vertically = true
            should_stay_on_min_side_a = false
            should_stay_on_min_side_b = true
            # Right end (counter-clockwise end).
            position_a = colliding_surface.first_point + \
                    Vector2(constraint_offset.x, constraint_offset.y)
            # Left end (clockwise end).
            position_b = colliding_surface.last_point + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
        SurfaceSide.LEFT_WALL:
            passing_vertically = false
            should_stay_on_min_side_a = true
            should_stay_on_min_side_b = false
            # Top end (counter-clockwise end).
            position_a = colliding_surface.first_point + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
            # Bottom end (clockwise end).
            position_b = colliding_surface.last_point + \
                    Vector2(constraint_offset.x, constraint_offset.y)
        SurfaceSide.RIGHT_WALL:
            passing_vertically = false
            should_stay_on_min_side_a = false
            should_stay_on_min_side_b = true
            # Bottom end (counter-clockwise end).
            position_a = colliding_surface.first_point + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
            # Top end (clockwise end).
            position_b = colliding_surface.last_point + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
    
    var should_skip_a := false
    var should_skip_b := false
    
    # We ignore constraints that would correspond to moving back the way we came.
    if previous_constraint.surface == colliding_surface.convex_counter_clockwise_neighbor:
        should_skip_a = true
    if previous_constraint.surface == colliding_surface.convex_clockwise_neighbor:
        should_skip_b = true
    
    # We ignore constraints that are redundant with the connstraint we were already using with the
    # previous step attempt.
    # 
    # These indicate a problem with our step logic somewhere though, so we log an error.
    if position_a == next_constraint.position:
        should_skip_a = true
        Utils.error("Calculated a rendundant constraint (same position as the next constraint)", \
                false)
    if position_b == next_constraint.position:
        should_skip_b = true
        Utils.error("Calculated a rendundant constraint (same position as the next constraint)", \
                false)
    
    # FIXME: DEBUGGING: REMOVE
#    if colliding_surface.normal.x == -1 and \
#            colliding_surface.bounding_box.position == Vector2(128, 64) and \
#            Geometry.are_points_equal_with_epsilon(position_a, Vector2(106, 37.5), 0.01):
#        print("break")
    
    var constraint_a_original: MovementConstraint
    var constraint_a_final: MovementConstraint
    var constraint_b_original: MovementConstraint
    var constraint_b_final: MovementConstraint
    
    if !should_skip_a:
        constraint_a_original = MovementConstraint.new(colliding_surface, position_a, \
                passing_vertically, should_stay_on_min_side_a, previous_constraint, \
                next_constraint)
        # Calculate and record state for the constraint.
        update_constraint(constraint_a_original, origin_constraint, movement_params, \
                vertical_step.velocity_step_start, vertical_step.can_hold_jump_button, \
                vertical_step, Vector2.INF)
        # If the constraint is fake, then replace it with its real neighbor, and re-calculate state
        # for the neighbor.
        if constraint_a_original.is_fake:
            constraint_a_final = _calculate_replacement_for_fake_constraint( \
                    constraint_a_original, constraint_offset)
            update_constraint(constraint_a_final, origin_constraint, movement_params, \
                    vertical_step.velocity_step_start, vertical_step.can_hold_jump_button, \
                    vertical_step, Vector2.INF)
        else:
            constraint_a_final = constraint_a_original
    
    if !should_skip_b:
        constraint_b_original = MovementConstraint.new(colliding_surface, position_b, \
                passing_vertically, should_stay_on_min_side_b, previous_constraint, \
                next_constraint)
        # Calculate and record state for the constraint.
        update_constraint(constraint_b_original, origin_constraint, movement_params, \
                vertical_step.velocity_step_start, vertical_step.can_hold_jump_button, \
                vertical_step, Vector2.INF)
        # If the constraint is fake, then replace it with its real neighbor, and re-calculate state
        # for the neighbor.
        if constraint_b_original.is_fake:
            constraint_b_final = _calculate_replacement_for_fake_constraint( \
                    constraint_b_original, constraint_offset)
            update_constraint(constraint_b_final, origin_constraint, movement_params, \
                    vertical_step.velocity_step_start, vertical_step.can_hold_jump_button, \
                    vertical_step, Vector2.INF)
        else:
            constraint_b_final = constraint_b_original
    
    if !should_skip_a and !should_skip_b:
        # Return the constraints in sorted order according to which is more likely to produce
        # successful movement.
        if _compare_constraints_by_more_likely_to_be_valid(constraint_a_original, constraint_b_original, \
                constraint_a_final, constraint_b_final, destination_constraint):
            return [constraint_a_final, constraint_b_final]
        else:
            return [constraint_b_final, constraint_a_final]
    elif !should_skip_a:
        return [constraint_a_final]
    elif !should_skip_b:
        return [constraint_b_final]
    else:
        Utils.error()
        return []

# Use some basic heuristics to sort the constraints. We try to attempt calculations for the 
# constraint that's most likely to be successful first.
static func _compare_constraints_by_more_likely_to_be_valid(a_original: MovementConstraint, \
        b_original: MovementConstraint, a_final: MovementConstraint, \
        b_final: MovementConstraint, destination: MovementConstraint) -> bool:
    if a_final.is_valid != b_final.is_valid:
        # Sort constraints according to whether they're valid.
        return a_final.is_valid
    else:
        # Sort constraints according to position.
        
        var colliding_surface := a_original.surface
        
        if colliding_surface.side == SurfaceSide.FLOOR:
            # When moving around a floor, prefer whichever constraint is closer to the destination.
            # 
            # TODO: Explain rationale.
            return a_original.position.distance_squared_to(destination.position) <= \
                    b_original.position.distance_squared_to(destination.position)
        elif colliding_surface.side == SurfaceSide.CEILING:
            # When moving around a ceiling, prefer whichever constraint is closer to the origin.
            # 
            # TODO: Explain rationale.
            return a_original.position.distance_squared_to(destination.position) >= \
                    b_original.position.distance_squared_to(destination.position)
        else:
            # When moving around walls, prefer whichever constraint is higher.
            # 
            # The reasoning here is that the constraint around the bottom edge of a wall will usually
            # require movement to use a lower jump height, which would then invalidate the rest of the
            # movement to the destination.
            return a_original.position.y >= b_original.position.y

# Calculates and records various state on the given constraint.
# 
# In particular, these constraint properties are updated:
# - is_fake
# - is_valid
# - horizontal_movement_sign
# - horizontal_movement_sign_from_displacement
# - time_passing_through
# - min_velocity_x
# - max_velocity_x
# 
# These calculations take into account state from previous and upcoming neighbor constraints as
# well as various other parameters.
# 
# Returns false if the constraint cannot satisfy the given parameters.
static func update_constraint(constraint: MovementConstraint, \
        origin_constraint: MovementConstraint, movement_params: MovementParams, \
        velocity_start_origin: Vector2, can_hold_jump_button_at_origin: bool, \
        vertical_step: MovementVertCalcStep, additional_high_constraint_position: Vector2) -> void:
    # Previous constraint, next constraint,  and vertical_step should be provided when updating
    # intermediate constraints.
    assert(constraint.previous_constraint != null or constraint.is_origin)
    assert(constraint.next_constraint != null or constraint.is_destination)
    assert(vertical_step != null or constraint.is_destination or constraint.is_origin)
    
    # additional_high_constraint_position should only ever be provided for the destination, and
    # then only when we're doing backtracking for a new jump-height.
    assert(additional_high_constraint_position == Vector2.INF or constraint.is_destination)
    assert(vertical_step != null or additional_high_constraint_position == Vector2.INF)
    
    _assign_horizontal_movement_sign(constraint, velocity_start_origin)
    
    var is_a_horizontal_surface := constraint.surface != null and constraint.surface.normal.x == 0
    var is_a_fake_constraint := constraint.surface != null and \
            constraint.horizontal_movement_sign != \
                    constraint.horizontal_movement_sign_from_displacement and \
            is_a_horizontal_surface
    
    if is_a_fake_constraint:
        # This constraint should be skipped, and movement should proceed directly to the next one
        # (but we still need to keep this constraint around long enough to calculate what that
        # next constraint is).
        constraint.is_fake = true
        constraint.horizontal_movement_sign = constraint.horizontal_movement_sign_from_displacement
        constraint.is_valid = false
    else:
        constraint.is_valid = _update_constraint_velocity_and_time(constraint, origin_constraint, \
                movement_params, velocity_start_origin, can_hold_jump_button_at_origin, \
                vertical_step, additional_high_constraint_position)

# Calculates and records various state on the given constraint.
# 
# In particular, these constraint properties are updated:
# - time_passing_through
# - min_velocity_x
# - max_velocity_x
# 
# These calculations take into account state from neighbor constraints as well as various other
# parameters.
# 
# Returns false if the constraint cannot satisfy the given parameters.
static func _update_constraint_velocity_and_time(constraint: MovementConstraint, \
        origin_constraint: MovementConstraint, movement_params: MovementParams, \
        velocity_start_origin: Vector2, can_hold_jump_button_at_origin: bool, \
        vertical_step: MovementVertCalcStep, additional_high_constraint_position: Vector2) -> bool:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    
    var time_passing_through: float
    var min_velocity_x: float
    var max_velocity_x: float
    var actual_velocity_x: float
    
    # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE:
#    if Geometry.are_points_equal_with_epsilon( \
#            constraint.position, \
#            Vector2(-190, -349), 10):
#        print("break")
    
    # Calculate the time that the movement would pass through the constraint, as well as the min
    # and max x-velocity when passing through the constraint.
    if constraint.is_origin:
        time_passing_through = 0.0
        min_velocity_x = velocity_start_origin.x
        max_velocity_x = velocity_start_origin.x
        actual_velocity_x = velocity_start_origin.x
    else:
        var displacement := constraint.next_constraint.position - constraint.position if \
                constraint.next_constraint != null else \
                constraint.position - constraint.previous_constraint.position
        
        # Check whether the vertical displacement is possible.
        if displacement.y < -movement_params.max_upward_jump_distance:
            # We can't reach the next constraint from this constraint.
            return false
        
        if constraint.is_destination:
            # For the destination constraint, we need to calculate time_to_release_jump. All other
            # constraints can re-use this information from the vertical_step.
            
            var time_to_release_jump: float
            
            # We consider different parameters if we are starting a new movement calculation vs
            # backtracking to consider a new jump height.
            var constraint_position_to_calculate_jump_release_time_for: Vector2
            if additional_high_constraint_position == Vector2.INF:
                # We are starting a new movement calculation (not backtracking to consider a new
                # jump height).
                constraint_position_to_calculate_jump_release_time_for = constraint.position
            else:
                # We are backtracking to consider a new jump height.
                constraint_position_to_calculate_jump_release_time_for = \
                        additional_high_constraint_position
                # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE:
#                if Geometry.are_points_equal_with_epsilon( \
#                        constraint_position_to_calculate_jump_release_time_for, \
#                        Vector2(64, -480), 10):
#                    print("break")
            
            # TODO: I should probably refactor these two calls, so we're doing fewer redundant
            #       calculations here.
            
            # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE:
#            if Geometry.are_points_equal_with_epsilon( \
#                    constraint.previous_constraint.position, \
#                    Vector2(64, -480), 10):
#                print("break")
            # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE:
#            if Geometry.are_points_equal_with_epsilon( \
#                    constraint.position, \
#                    Vector2(2688, 226), 10):
#                print("break")
            
            var displacement_from_origin_to_constraint := \
                    constraint_position_to_calculate_jump_release_time_for - \
                    origin_constraint.position
            
            # If we already know the required time for reaching the destination, and we aren't
            # performing a new backtracking step, then re-use the previously calculated time. The
            # previous value encompasses more information that we may need to preserve, such as
            # whether we already did some backtracking.
            var time_to_pass_through_constraint_ignoring_others: float
            if vertical_step != null and additional_high_constraint_position == Vector2.INF:
                time_to_pass_through_constraint_ignoring_others = vertical_step.time_step_end
            else:
                time_to_pass_through_constraint_ignoring_others = \
                        VerticalMovementUtils.calculate_time_to_jump_to_constraint(movement_params, \
                                displacement_from_origin_to_constraint, velocity_start_origin, \
                                can_hold_jump_button_at_origin, \
                                additional_high_constraint_position != Vector2.INF)
                if time_to_pass_through_constraint_ignoring_others == INF:
                    # We can't reach this constraint.
                    return false
                assert(time_to_pass_through_constraint_ignoring_others > 0.0)
            
            if additional_high_constraint_position != Vector2.INF:
                # We are backtracking to consider a new jump height.
                # 
                # The destination jump time should account for all of the following:
                # 
                # -   The time needed to reach any previous jump-heights before this current round
                #     of jump-height backtracking (vertical_step.time_instruction_end).
                # -   The time needed to reach this new previously-out-of-reach constraint
                #     (time_to_release_jump for the new constraint).
                # -   The time needed to get to the destination from this new constraint.
                
                # TODO: There might be cases that this fails for? We might need to add more time.
                #       Revisit this if we see problems.
                
                var time_to_get_to_destination_from_constraint := \
                        _calculate_time_to_reach_destination_from_new_constraint(movement_params, \
                                additional_high_constraint_position, constraint)
                if time_to_get_to_destination_from_constraint == INF:
                    # We can't reach the destination from this constraint.
                    return false
                
                time_passing_through = max(vertical_step.time_step_end, \
                        time_to_pass_through_constraint_ignoring_others + \
                                time_to_get_to_destination_from_constraint)
                
            else:
                time_passing_through = time_to_pass_through_constraint_ignoring_others
            
            # We can't be more restrictive with the destination velocity limits, because otherwise,
            # origin vs intermediate constraints give us all sorts of invalid values, which they
            # in-turn base their values off of.
            # 
            # Specifically, when the horizontal movement sign of the destination changes, due to a
            # new intermediate constraint, either the min or max would be incorrectly capped at 0
            # when we're calculating the min/max for the new constraint.
            min_velocity_x = -movement_params.max_horizontal_speed_default
            max_velocity_x = movement_params.max_horizontal_speed_default
            
        else:
            # This is an intermediate constraint (not the origin or destination).
            time_passing_through = \
                    VerticalMovementUtils.calculate_time_for_passing_through_constraint( \
                            movement_params, constraint, \
                            constraint.previous_constraint.time_passing_through + 0.0001, \
                            vertical_step.position_step_start.y, \
                            vertical_step.velocity_step_start.y, \
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
                    !still_holding_jump_button:
                # Quit early if we are trying to go above a wall, but we already released the jump
                # button.
                return false
            elif !constraint.passing_vertically and !constraint.should_stay_on_min_side and \
                    still_holding_jump_button:
                # Quit early if we are trying to go below a wall, but we are still holding the jump
                # button.
                return false
            else:
                # We should never hit a floor while still holding the jump button.
                assert(!(constraint.surface != null and \
                        constraint.surface.side == SurfaceSide.FLOOR and \
                        still_holding_jump_button))
            
            var duration_to_next := \
                    constraint.next_constraint.time_passing_through - time_passing_through
            if duration_to_next <= 0:
                # We can't reach the next constraint from this constraint.
                return false
            
            var displacement_to_next := displacement
            var duration_from_origin := \
                    time_passing_through - origin_constraint.time_passing_through
            var displacement_from_origin := constraint.position - origin_constraint.position
            
            # FIXME: DEBUGGING: REMOVE
#            if Geometry.are_floats_equal_with_epsilon(min_velocity_x, -112.517, 0.01):
#            if Geometry.are_floats_equal_with_epsilon(duration_to_next, 0.372, 0.01) and \
#                    displacement_to_next.x == 62:
#                print("break")
            
            # We calculate min/max velocity limits for direct movement from the origin. These
            # limits are more permissive than if we were calculating them from the actual
            # immediately previous constraint, but these can give an early indicator for whether
            # this constraint is invalid.
            # 
            # NOTE: This check will still not guarantee that movement up to this constraint can be
            #       reached, since any previous intermediate constraints could invalidate things.
            var min_and_max_velocity_from_origin := \
                    _calculate_min_and_max_x_velocity_at_end_of_interval( \
                            displacement_from_origin.x, duration_from_origin, \
                            origin_constraint.min_velocity_x, \
                            origin_constraint.max_velocity_x, \
                            movement_params.max_horizontal_speed_default, \
                            movement_params.in_air_horizontal_acceleration, \
                            constraint.horizontal_movement_sign)
            if min_and_max_velocity_from_origin.empty():
                # We can't reach this constraint from the previous constraint.
                return false
            var min_velocity_x_from_origin: float = min_and_max_velocity_from_origin[0]
            var max_velocity_x_from_origin: float = min_and_max_velocity_from_origin[1]
            
            # Calculate the min and max velocity for movement through the constraint.
            var min_and_max_velocity_for_next_step := \
                    _calculate_min_and_max_x_velocity_at_start_of_interval( \
                            displacement_to_next.x, duration_to_next, \
                            constraint.next_constraint.min_velocity_x, \
                            constraint.next_constraint.max_velocity_x, \
                            movement_params.max_horizontal_speed_default, \
                            movement_params.in_air_horizontal_acceleration, \
                            constraint.horizontal_movement_sign)
            if min_and_max_velocity_for_next_step.empty():
                # We can't reach the next constraint from this constraint.
                return false
            var min_velocity_x_for_next_step: float = min_and_max_velocity_for_next_step[0]
            var max_velocity_x_for_next_step: float = min_and_max_velocity_for_next_step[1]
            
            min_velocity_x = max(min_velocity_x_from_origin, min_velocity_x_for_next_step)
            max_velocity_x = min(max_velocity_x_from_origin, max_velocity_x_for_next_step)
        
        # actual_velocity_x is calculated when calculating the horizontal steps.
        actual_velocity_x = INF
    
    constraint.time_passing_through = time_passing_through
    constraint.min_velocity_x = min_velocity_x
    constraint.max_velocity_x = max_velocity_x
    constraint.actual_velocity_x = actual_velocity_x
    
    # FIXME: ---------------------- Debugging... Maybe remove the is_destination conditional?
    if !constraint.is_destination:
        # Ensure that the min and max velocities match the expected horizontal movement direction.
        if constraint.horizontal_movement_sign == 1:
            assert(constraint.min_velocity_x >= 0 and constraint.max_velocity_x >= 0)
        elif constraint.horizontal_movement_sign == -1:
            assert(constraint.min_velocity_x <= 0 and constraint.max_velocity_x <= 0)
    
    return true

# This only considers the time to move horizontally and the time to fall; this does not consider
# the time to rise from the new constraint to the destination.
# 
# - We don't consider rise time, since that would require knowing more information around when the
#   jump button is released and whether it could still be held. Also, this case is much less likely
#   to impact the overall movement duration.
# - For horizontal movement time, we don't need to know about vertical velocity or the jump button.
# - For fall time, we can assume that vertical velocity will be zero when passing through this new
#   constraint (since it should be the highest point we reach in the jump). If the movement would
#   require vertical velocity to _not_ be zero through this new constraint, then that case should
#   be covered by the horizontal time calculation.
static func _calculate_time_to_reach_destination_from_new_constraint( \
        movement_params: MovementParams, new_constraint_position: Vector2, \
        destination: MovementConstraint) -> float:
    var displacement := destination.position - new_constraint_position
    
    var velocity_x_at_new_constraint: float
    var acceleration: float
    if displacement.x > 0:
        velocity_x_at_new_constraint = movement_params.max_horizontal_speed_default * \
                CALCULATE_TIME_TO_REACH_DESTINATION_FROM_NEW_CONSTRAINT_V_X_MAX_SPEED_MULTIPLIER
        acceleration = movement_params.in_air_horizontal_acceleration
    else:
        velocity_x_at_new_constraint = -movement_params.max_horizontal_speed_default * \
                CALCULATE_TIME_TO_REACH_DESTINATION_FROM_NEW_CONSTRAINT_V_X_MAX_SPEED_MULTIPLIER
        acceleration = -movement_params.in_air_horizontal_acceleration
    
    var time_to_reach_horizontal_displacement := \
            MovementUtils.calculate_min_time_to_reach_displacement(displacement.x, \
                    velocity_x_at_new_constraint, movement_params.max_horizontal_speed_default, \
                    acceleration)
    
    var time_to_reach_fall_displacement: float
    if displacement.y > 0:
        time_to_reach_fall_displacement = MovementUtils.calculate_movement_duration( \
                displacement.y, 0.0, movement_params.gravity_fast_fall, true, 0.0, true)
    else:
        time_to_reach_fall_displacement = 0.0
    
    return max(time_to_reach_horizontal_displacement, time_to_reach_fall_displacement)

static func _assign_horizontal_movement_sign(constraint: MovementConstraint, \
        velocity_start_origin: Vector2) -> void:
    var previous_constraint := constraint.previous_constraint
    var next_constraint := constraint.next_constraint
    var is_origin := constraint.is_origin
    var is_destination := constraint.is_destination
    var surface := constraint.surface
    
    assert(surface != null or is_origin or is_destination)
    assert(previous_constraint != null or is_origin)
    assert(next_constraint != null or is_destination)
    
    var displacement := constraint.position - previous_constraint.position if \
            previous_constraint != null else next_constraint.position - constraint.position
    var neighbor_horizontal_movement_sign := previous_constraint.horizontal_movement_sign if \
            previous_constraint != null else next_constraint.horizontal_movement_sign
    
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
            (-neighbor_horizontal_movement_sign if neighbor_horizontal_movement_sign != INF else \
            # For straight vertical steps from the origin, we don't have much to go off of for
            # picking the horizontal movement direction, so just default to rightward for now.
            1))
    
    var horizontal_movement_sign: int
    if is_origin:
        horizontal_movement_sign = \
                1 if velocity_start_origin.x > 0 else \
                (-1 if velocity_start_origin.x < 0 else \
                horizontal_movement_sign_from_displacement)
    elif is_destination:
        horizontal_movement_sign = \
                -1 if surface != null and surface.side == SurfaceSide.LEFT_WALL else \
                (1 if surface != null and surface.side == SurfaceSide.RIGHT_WALL else \
                horizontal_movement_sign_from_displacement)
    else:
        horizontal_movement_sign = \
                -1 if surface.side == SurfaceSide.LEFT_WALL else \
                (1 if surface.side == SurfaceSide.RIGHT_WALL else \
                (-1 if constraint.should_stay_on_min_side else 1))
    
    constraint.horizontal_movement_sign = horizontal_movement_sign
    constraint.horizontal_movement_sign_from_displacement = \
            horizontal_movement_sign_from_displacement

# This calculates the range of possible x velocities at the start of a movement step.
# 
# This takes into consideration both:
# 
# - the given range of possible step-end x velocities that must be met in order for movement to be
#   valid for the next step,
# - and the range of possible step-start x velocities that can produce valid movement for the
#   current step.
# 
# An Array is returned:
# 
# - The first element represents the min velocity.
# - The second element represents the max velocity.
static func _calculate_min_and_max_x_velocity_at_start_of_interval(displacement: float, \
        duration: float, v_1_min_for_next_constraint: float, \
        v_1_max_for_next_constraint: float, speed_max: float, a_magnitude: float, \
        start_horizontal_movement_sign: int) -> Array:
    ### Calculate more tightly-bounded min/max end velocity values, according to both the duration
    ### of the current step and the given min/max values from the next constraint.
    
    # The strategy here, is to first try min/max v_1 values that correspond to accelerating over
    # the entire interval. If they do not result in movement that exceeds max speed, then we know
    # that they are the most extreme possible end velocities. Otherwise, if the movement would
    # exceed max speed, then we need to perform a slightly more expensive calculation that assumes
    # a two-part movement profile: one part with constant acceleration and one part with constant
    # velocity.
    
    # Accelerating in a positive direction over the entire step corresponds to an upper bound on
    # the end velocity and a lower boound on the start velocity, and accelerating in a negative
    # direction over the entire step corresponds to a lower bound on the end velocity and an upper
    # bound on the start velocity.
    # 
    # Derivation:
    # - From basic equations of motion:
    #   s = s_0 + v_0*t + 1/2*a*t^2
    #   v_1 = v_0 + a*t
    # - Algebra...
    #   v_1 = (s - s_0) / t + 1/2*a*t
    var min_v_1_with_complete_neg_acc_and_no_max_speed := \
            displacement / duration - 0.5 * a_magnitude * duration
    var max_v_1_with_complete_pos_acc_and_no_max_speed := \
            displacement / duration + 0.5 * a_magnitude * duration
    
    # From a basic equation of motion:
    #   v = v_0 + a*t
    var max_v_0_with_complete_neg_acc_and_no_max_speed := \
            min_v_1_with_complete_neg_acc_and_no_max_speed + a_magnitude * duration
    var min_v_0_with_complete_pos_acc_and_no_max_speed := \
            max_v_1_with_complete_pos_acc_and_no_max_speed - a_magnitude * duration
    
    var would_complete_neg_acc_exceed_max_speed_at_v_0 := \
            max_v_0_with_complete_neg_acc_and_no_max_speed > speed_max
    var would_complete_pos_acc_exceed_max_speed_at_v_0 := \
            min_v_0_with_complete_pos_acc_and_no_max_speed < -speed_max
    
    var min_v_1_from_partial_acc_and_no_max_speed_at_v_1: float
    var max_v_1_from_partial_acc_and_no_max_speed_at_v_1: float
    
    if would_complete_neg_acc_exceed_max_speed_at_v_0:
        # Accelerating over the entire step to min_v_1_that_can_be_reached would require starting
        # with a velocity that exceeds max speed. So we need to instead consider a two-part
        # movement profile when calculating min_v_1_that_can_be_reached: constant velocity
        # followed by constant acceleration. Accelerating at the end, given the same start
        # velocity, should result in a more extreme end velocity, than accelerating at the start.
        var acceleration := -a_magnitude
        var v_0 := speed_max
        min_v_1_from_partial_acc_and_no_max_speed_at_v_1 = \
                _calculate_v_1_with_v_0_limit(displacement, duration, v_0, acceleration, true)
        if min_v_1_from_partial_acc_and_no_max_speed_at_v_1 == INF:
            # We cannot reach this constraint from the previous constraint.
            return []
    else:
        min_v_1_from_partial_acc_and_no_max_speed_at_v_1 = \
                min_v_1_with_complete_neg_acc_and_no_max_speed
    
    if would_complete_pos_acc_exceed_max_speed_at_v_0:
        # Accelerating over the entire step to max_v_1_that_can_be_reached would require starting
        # with a velocity that exceeds max speed. So we need to instead consider a two-part
        # movement profile when calculating max_v_1_that_can_be_reached: constant velocity
        # followed by constant acceleration. Accelerating at the end, given the same start
        # velocity, should result in a more extreme end velocity, than accelerating at the start.
        var acceleration := a_magnitude
        var v_0 := -speed_max
        max_v_1_from_partial_acc_and_no_max_speed_at_v_1 = \
                _calculate_v_1_with_v_0_limit(displacement, duration, v_0, acceleration, false)
        if max_v_1_from_partial_acc_and_no_max_speed_at_v_1 == INF:
            # We cannot reach this constraint from the previous constraint.
            return []
    else:
        max_v_1_from_partial_acc_and_no_max_speed_at_v_1 = \
                max_v_1_with_complete_pos_acc_and_no_max_speed
    
    # The min and max possible v_1 are dependent on both the duration of the current step and the
    # min and max possible start velocity from the next step, respectively.
    # 
    # The min/max from the next constraint will not exceed max speed, so it doesn't matter if
    # min_/max_v_1_from_partial_acc_and_no_max_speed exceed max speed.
    var v_1_min := max(min_v_1_from_partial_acc_and_no_max_speed_at_v_1, \
            v_1_min_for_next_constraint)
    var v_1_max := min(max_v_1_from_partial_acc_and_no_max_speed_at_v_1, \
            v_1_max_for_next_constraint)
    
    if v_1_min > v_1_max:
        # Neither direction of acceleration will work with the given min/max velocities from the
        # next constraint.
        return []
    
    ### Calculate min/max start velocities according to the min/max end velocities.
    
    # At this point, there are a few different parameters we can adjust in order to define the
    # movement from the previous constraint to the next (and to define the start velocity). These
    # parameters include:
    # 
    # - The end velocity.
    # - The direction of acceleration.
    # - When during the interval to apply acceleration (in this function, we only need to consider
    #   acceleration at the very end or the very beginning of the step, since those will correspond
    #   to upper and lower bounds on the start velocity).
    # 
    # The general strategy then is to pick values for these parameters that will produce the most
    # extreme start velocities. We then calculate a few possible combinations of these parameters,
    # and return the resulting min/max start velocities. This should work, because any velocity
    # between the resulting min and max should be achievable (since the actual final movement will
    # support applying acceleration at any point in the middle of the step).
    #
    # Some notes about parameter selection:
    # 
    # - Min and max end velocities correspond to max and min start velocities, respectively.
    # - If negative acceleration is used during this interval, then we want to accelerate at
    #   the start of the interval to find the max start velocity and accelerate at the end of the
    #   interval to find the min start velocity.
    # - If positive acceleration is used during this interval, then we want to accelerate at
    #   the end of the interval to find the max start velocity and accelerate at the start of the
    #   interval to find the min start velocity.
    # - All of the above is true regardless of the direction of displacement for the interval.
    
    # FIXME: If I see any problems from this logic, then just calculate the other four cases too,
    #        and use the best valid ones from the whole set of 8.
    
    var v_1: float
    var acceleration: float
    var should_accelerate_at_start: bool
    var should_return_min_result: bool
    var v_0_min: float
    var v_0_max: float
    
    if would_complete_neg_acc_exceed_max_speed_at_v_0:
        v_1 = v_1_min
        acceleration = -a_magnitude
        should_accelerate_at_start = true
        should_return_min_result = false
        var v_0_max_neg_acc_at_start := _solve_for_start_velocity(displacement, duration, \
                acceleration, v_1, should_accelerate_at_start, should_return_min_result)
        
        v_1 = v_1_min
        acceleration = a_magnitude
        should_accelerate_at_start = false
        should_return_min_result = false
        var v_0_max_pos_acc_at_end := _solve_for_start_velocity(displacement, duration, \
                acceleration, v_1, should_accelerate_at_start, should_return_min_result)
        
        # Use the more extreme of the possible min/max values we calculated for positive/negative
        # acceleration at the start/end.
        v_0_max = \
                max(v_0_max_neg_acc_at_start, v_0_max_pos_acc_at_end) if \
                        v_0_max_neg_acc_at_start != INF and v_0_max_pos_acc_at_end != INF else \
                (v_0_max_neg_acc_at_start if v_0_max_neg_acc_at_start != INF else \
                v_0_max_pos_acc_at_end)
    else:
        # FIXME: LEFT OFF HERE: Does this need to account for accurate displacement values or anything?
        
        # - From a basic equation of motion:
        #   v = v_0 + a*t
        # - Uses negative acceleration.
        v_0_max = v_1_min + a_magnitude * duration
    
    if would_complete_pos_acc_exceed_max_speed_at_v_0:
        v_1 = v_1_max
        acceleration = a_magnitude
        should_accelerate_at_start = true
        should_return_min_result = true
        var v_0_min_pos_acc_at_start := _solve_for_start_velocity(displacement, duration, \
                acceleration, v_1, should_accelerate_at_start, should_return_min_result)
        
        v_1 = v_1_max
        acceleration = -a_magnitude
        should_accelerate_at_start = false
        should_return_min_result = true
        var v_0_min_neg_acc_at_end := _solve_for_start_velocity(displacement, duration, \
                acceleration, v_1, should_accelerate_at_start, should_return_min_result)
        
        # Use the more extreme of the possible min/max values we calculated for positive/negative
        # acceleration at the start/end.
        v_0_min = \
                min(v_0_min_pos_acc_at_start, v_0_min_neg_acc_at_end) if \
                        v_0_min_pos_acc_at_start != INF and v_0_min_neg_acc_at_end != INF else \
                (v_0_min_pos_acc_at_start if v_0_min_pos_acc_at_start != INF else \
                v_0_min_neg_acc_at_end)
    else:
        # FIXME: LEFT OFF HERE: Does this need to account for accurate displacement values or anything?
        
        # - From a basic equation of motion:
        #   v = v_0 + a*t
        # - Uses positive acceleration.
        v_0_min = v_1_max - a_magnitude * duration
    
    ### Sanitize the results (remove invalid results, cap values, correct for round-off errors).
    
    # If we found valid v_1_min/v_1_max values, then there must be valid corresponding
    # v_0_min/v_0_max values.
    assert(v_0_max != INF)
    assert(v_0_min != INF)
    assert(v_0_max >= v_0_min)
    
    # Add a small offset to the min and max to help with round-off errors.
    v_0_min += MIN_MAX_VELOCITY_X_OFFSET
    v_0_max -= MIN_MAX_VELOCITY_X_OFFSET
    
    # Correct small floating-point errors around zero.
    if Geometry.are_floats_equal_with_epsilon(v_0_min, 0.0, MIN_MAX_VELOCITY_X_OFFSET * 1.1):
        v_0_min = 0.0
    if Geometry.are_floats_equal_with_epsilon(v_0_max, 0.0, MIN_MAX_VELOCITY_X_OFFSET * 1.1):
        v_0_max = 0.0
    
    if (start_horizontal_movement_sign > 0 and v_0_max < 0) or \
        (start_horizontal_movement_sign < 0 and v_0_min > 0):
        # We cannot reach the next constraint with the needed movement direction.
        return []
    
    # Limit velocity to the expected movement direction for this constraint.
    if start_horizontal_movement_sign > 0:
        v_0_min = max(v_0_min, 0.0)
    else:
        v_0_max = min(v_0_max, 0.0)
    
    # Limit max speeds.
    if v_0_min > speed_max or v_0_max < -speed_max:
        # We cannot reach the next constraint from the previous constraint.
        return []
    v_0_max = min(v_0_max, speed_max)
    v_0_min = max(v_0_min, -speed_max)
    
    return [v_0_min, v_0_max]

# Accelerating over the whole interval would result in an end velocity that exceeds the max speed.
# So instead, we assume a 2-part movement profile with constant velocity in the first part and
# constant acceleration in the second part. This 2-part movement should more accurately represent
# the limit on v_1.
static func _calculate_v_1_with_v_0_limit(displacement: float, duration: float, v_0: float, \
        acceleration: float, should_return_min_result: bool) -> float:
    # Derivation:
    # - From basic equations of motion:
    #   - s_1 = s_0 + v_0*t_0
    #   - v_1 = v_0 + a*t_1
    #   - v_1^2 = v_0^2 + 2*a*(s_2 - s_1)
    #   - t_total = t_0 + t_1
    #   - diplacement = s_2 - s_0
    # - Do some algebra...
    #   - 0 = 2*a*(displacement - v_0*t_total) - v_0^2 + 2*v_0*v_1 - v_1^2
    # - Apply quadratic formula to solve for v_1.
    
    var a := -1
    var b := 2 * v_0
    var c := 2 * acceleration * (displacement - v_0 * duration) - v_0 * v_0
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # There is no end velocity that can satisfy these parameters.
        return INF
    
    var discriminant_sqrt := sqrt(discriminant)
    var result_1 := (-b + discriminant_sqrt) / 2.0 / a
    var result_2 := (-b - discriminant_sqrt) / 2.0 / a
    
    # From a basic equation of motion:
    #    v_1 = v_0 + a*t
    var t_result_1 := (result_1 - v_0) / acceleration
    var t_result_2 := (result_2 - v_0) / acceleration
    
    # The results are invalid if they correspond to imaginary negative durations.
    var is_result_1_valid := (t_result_1 >= 0 and t_result_1 <= duration)
    var is_result_2_valid := (t_result_2 >= 0 and t_result_2 <= duration)
    
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

static func _solve_for_start_velocity(displacement: float, duration: float, acceleration: float, \
        v_1: float, should_accelerate_at_start: bool, should_return_min_result: bool) -> float:
    var acceleration_sign := 1 if acceleration >= 0 else -1
    
    var a: float
    var b: float
    var c: float
    
    # FIXME: -------------- REMOVE: DEBUGGING
#    duration = 1.3
    
    # We only need to consider two movement profiles:
    # 
    # - Accelerate at start (2 parts):
    #   - First, constant acceleration to v_1.
    #   - Then, constant velocity at v_1 for the remaining duration.
    # - Accelerate at end (2 parts):
    #   - First, constant velocity at v_0.
    #   - Then, constant acceleration for the remaining duration, ending at v_1.
    # 
    # No other movement profile--e.g., 3-part with constant v at v_0, accelerate to v_1, constant
    # v at v_1--should produce more extreme start velocities, so we only need to consider these
    # two. Any considerations for capping at max-speed will be handled by the consumer function
    # that calls this one.
    
    if should_accelerate_at_start:
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant acceleration from v_0 to v_1.
        #   - Part 2: Coast at v_1 until we reach the destination.
        # - Start with basic equations of motion:
        #   - v_1 = v_0 + a*t_0
        #   - s_2 = s_1 + v_1*t_1
        #   - v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
        #   - t_total = t_0 + t_1
        #   - displacement = s_2 - s_0
        # - Do some algebra...
        #   - 0 = 2*a*(displacement - v_1*t) + v_1^2 - 2*v_1*v_0 + v_0^2
        # - Apply quadratic formula to solve for v_0.
        a = 1
        b = -2 * v_1
        c = 2 * acceleration * (displacement - v_1 * duration) + v_1 * v_1
    else:
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant velocity at v_0.
        #   - Part 2: Constant acceleration for the remaining duration, ending at v_1.
        # - Start with basic equations of motion:
        #   - s_1 = s_0 + v_0*t_0
        #   - v_1 = v_0 + a*t_1
        #   - v_1^2 = v_0^2 + 2*a*(s_2 - s_1)
        #   - t_total = t_0 + t_1
        #   - displacement = s_2 - s_0
        # - Do some algebra...
        #   - 0 = 2*a*displacement - v_1^2 + 2*(v_1 - a*t_total)*v_0 - v_0^2
        # - Apply quadratic formula to solve for v_0.
        a = -1
        b = 2 * (v_1 - acceleration * duration)
        c = 2 * acceleration * displacement - v_1 * v_1
    
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
    
    ###########################################
    # FIXME: --------------- REMOVE: DEBUGGING
#    var disp_result_1_foo := v_0*t_result_1 + 0.5*acceleration*t_result_1*t_result_1
#    var disp_result_1_bar := result_1*(duration-t_result_1)
#    var disp_result_1_total := disp_result_1_foo + disp_result_1_bar
#    var disp_result_2_foo := v_0*t_result_2 + 0.5*acceleration*t_result_2*t_result_2
#    var disp_result_2_bar := result_2*(duration-t_result_2)
#    var disp_result_2_total := disp_result_2_foo + disp_result_2_bar
    ###########################################
    
    # The results are invalid if they correspond to imaginary negative durations.
    var is_result_1_valid := t_result_1 >= 0 and t_result_1 <= duration
    var is_result_2_valid := t_result_2 >= 0 and t_result_2 <= duration
    
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

# This calculates the range of possible x velocities at the end of a movement step.
# 
# This takes into consideration both:
# 
# - the given range of possible step-start x velocities that must be met in order for movement to be
#   valid for the previous step,
# - and the range of possible step-end x velocities that can produce valid movement for the
#   current step.
# 
# An Array is returned:
# 
# - The first element represents the min velocity.
# - The second element represents the max velocity.
static func _calculate_min_and_max_x_velocity_at_end_of_interval(displacement: float, \
        duration: float, v_1_min_for_previous_constraint: float, \
        v_1_max_for_previous_constraint: float, speed_max: float, a_magnitude: float, \
        end_horizontal_movement_sign: int) -> Array:
    ### Calculate more tightly-bounded min/max start velocity values, according to both the duration
    ### of the current step and the given min/max values from the previous constraint.
    
    # The strategy here, is to first try min/max v_0 values that correspond to accelerating over
    # the entire interval. If they do not result in movement that exceeds max speed, then we know
    # that they are the most extreme possible start velocities. Otherwise, if the movement would
    # exceed max speed, then we need to perform a slightly more expensive calculation that assumes
    # a two-part movement profile: one part with constant acceleration and one part with constant
    # velocity.
    
    # Accelerating in a positive direction over the entire step corresponds to an upper bound on
    # the end velocity and a lower boound on the start velocity, and accelerating in a negative
    # direction over the entire step corresponds to a lower bound on the end velocity and an upper
    # bound on the start velocity.
    # 
    # Derivation:
    # - From basic equations of motion:
    #   s = s_0 + v_0*t + 1/2*a*t^2
    # - Algebra...
    #   v_0 = (s - s_0) / t - 1/2*a*t
    var min_v_0_with_complete_pos_acc_and_no_max_speed := \
            displacement / duration - 0.5 * a_magnitude * duration
    var max_v_0_with_complete_neg_acc_and_no_max_speed := \
            displacement / duration + 0.5 * a_magnitude * duration
    
    # From a basic equation of motion:
    #   v_1 = v_0 + a*t
    var max_v_1_with_complete_pos_acc_and_no_max_speed := \
            min_v_0_with_complete_pos_acc_and_no_max_speed + a_magnitude * duration
    var min_v_1_with_complete_neg_acc_and_no_max_speed := \
            max_v_0_with_complete_neg_acc_and_no_max_speed - a_magnitude * duration
    
    var would_complete_pos_acc_exceed_max_speed_at_v_1 := \
            max_v_1_with_complete_pos_acc_and_no_max_speed > speed_max
    var would_complete_neg_acc_exceed_max_speed_at_v_1 := \
            min_v_1_with_complete_neg_acc_and_no_max_speed < -speed_max
    
    var min_v_0_from_partial_acc_and_no_max_speed_at_v_0: float
    var max_v_0_from_partial_acc_and_no_max_speed_at_v_0: float
    
    if would_complete_pos_acc_exceed_max_speed_at_v_1:
        # Accelerating over the entire step to min_v_0_that_can_reach_target would require ending
        # with a velocity that exceeds max speed. So we need to instead consider a two-part
        # movement profile when calculating min_v_0_that_can_reach_target: constant acceleration
        # followed by constant velocity. Accelerating at the start, given the same end velocity,
        # should result in a more extreme start velocity, than accelerating at the end.
        var acceleration := a_magnitude
        var v_1 := speed_max
        min_v_0_from_partial_acc_and_no_max_speed_at_v_0 = \
                _calculate_v_0_with_v_1_limit(displacement, duration, v_1, acceleration, true)
        if min_v_0_from_partial_acc_and_no_max_speed_at_v_0 == INF:
            # We cannot reach this constraint from the previous constraint.
            return []
    else:
        min_v_0_from_partial_acc_and_no_max_speed_at_v_0 = \
                min_v_0_with_complete_pos_acc_and_no_max_speed
    
    if would_complete_neg_acc_exceed_max_speed_at_v_1:
        # Accelerating over the entire step to max_v_0_that_can_reach_target would require ending
        # with a velocity that exceeds max speed. So we need to instead consider a two-part
        # movement profile when calculating max_v_0_that_can_reach_target: constant acceleration
        # followed by constant velocity. Accelerating at the start, given the same end velocity,
        # should result in a more extreme start velocity, than accelerating at the end.
        var acceleration := -a_magnitude
        var v_1 := -speed_max
        max_v_0_from_partial_acc_and_no_max_speed_at_v_0 = \
                _calculate_v_0_with_v_1_limit(displacement, duration, v_1, acceleration, false)
        if max_v_0_from_partial_acc_and_no_max_speed_at_v_0 == INF:
            # We cannot reach this constraint from the previous constraint.
            return []
    else:
        max_v_0_from_partial_acc_and_no_max_speed_at_v_0 = \
                max_v_0_with_complete_neg_acc_and_no_max_speed
    
    # The min and max possible v_0 are dependent on both the duration of the current step and the
    # min and max possible end velocity from the previous step, respectively.
    # 
    # The min/max from the previous constraint will not exceed max speed, so it doesn't matter if
    # min_/max_v_0_from_partial_acc_and_no_max_speed exceed max speed.
    var v_0_min := max(min_v_0_from_partial_acc_and_no_max_speed_at_v_0, \
            v_1_min_for_previous_constraint)
    var v_0_max := min(max_v_0_from_partial_acc_and_no_max_speed_at_v_0, \
            v_1_max_for_previous_constraint)
    
    if v_0_min > v_0_max:
        # Neither direction of acceleration will work with the given min/max velocities from the
        # previous constraint.
        return []
    
    ### Calculate min/max end velocities according to the min/max start velocities.
    
    # At this point, there are a few different parameters we can adjust in order to define the
    # movement from the previous constraint to the next (and to define the start velocity). These
    # parameters include:
    # 
    # - The start velocity.
    # - The direction of acceleration.
    # - When during the interval to apply acceleration (in this function, we only need to consider
    #   acceleration at the very end or the very beginning of the step, since those will correspond
    #   to upper and lower bounds on the end velocity).
    # 
    # The general strategy then is to pick values for these parameters that will produce the most
    # extreme end velocities. We then calculate a few possible combinations of these parameters,
    # and return the resulting min/max end velocities. This should work, because any velocity
    # between the resulting min and max should be achievable (since the actual final movement will
    # support applying acceleration at any point in the middle of the step).
    #
    # Some notes about parameter selection:
    # 
    # - Min and max start velocities correspond to max and min end velocities, respectively.
    # - If negative acceleration is used during this interval, then we want to accelerate at
    #   the start of the interval to find the max end velocity and accelerate at the end of the
    #   interval to find the min end velocity.
    # - If positive acceleration is used during this interval, then we want to accelerate at
    #   the end of the interval to find the max end velocity and accelerate at the start of the
    #   interval to find the min end velocity.
    # - All of the above is true regardless of the direction of displacement for the interval.
    
    # FIXME: If I see any problems from this logic, then just calculate the other four cases too,
    #        and use the best valid ones from the whole set of 8.
    
    var v_0: float
    var acceleration: float
    var should_accelerate_at_start: bool
    var should_return_min_result: bool
    var v_1_min: float
    var v_1_max: float
    
    if would_complete_pos_acc_exceed_max_speed_at_v_1:
        v_0 = v_0_min
        acceleration = -a_magnitude
        should_accelerate_at_start = true
        should_return_min_result = false
        var v_1_max_neg_acc_at_start := _solve_for_end_velocity(displacement, duration, \
                acceleration, v_0, should_accelerate_at_start, should_return_min_result)
        
        v_0 = v_0_min
        acceleration = a_magnitude
        should_accelerate_at_start = false
        should_return_min_result = false
        var v_1_max_pos_acc_at_end := _solve_for_end_velocity(displacement, duration, \
                acceleration, v_0, should_accelerate_at_start, should_return_min_result)
        
        # Use the more extreme of the possible min/max values we calculated for positive/negative
        # acceleration at the start/end.
        v_1_max = \
                max(v_1_max_neg_acc_at_start, v_1_max_pos_acc_at_end) if \
                        v_1_max_neg_acc_at_start != INF and v_1_max_pos_acc_at_end != INF else \
                (v_1_max_neg_acc_at_start if v_1_max_neg_acc_at_start != INF else \
                v_1_max_pos_acc_at_end)
    else:
        # FIXME: LEFT OFF HERE: Does this need to account for accurate displacement values or anything?
        
        # - From a basic equation of motion:
        #   v = v_0 + a*t
        # - Uses positive acceleration.
        v_1_max = v_0_min + a_magnitude * duration
    
    if would_complete_neg_acc_exceed_max_speed_at_v_1:
        v_0 = v_0_max
        acceleration = a_magnitude
        should_accelerate_at_start = true
        should_return_min_result = true
        var v_1_min_pos_acc_at_start := _solve_for_end_velocity(displacement, duration, \
                acceleration, v_0, should_accelerate_at_start, should_return_min_result)
        
        v_0 = v_0_max
        acceleration = -a_magnitude
        should_accelerate_at_start = false
        should_return_min_result = true
        var v_1_min_neg_acc_at_end := _solve_for_end_velocity(displacement, duration, \
                acceleration, v_0, should_accelerate_at_start, should_return_min_result)
        
        # Use the more extreme of the possible min/max values we calculated for positive/negative
        # acceleration at the start/end.
        v_1_min = \
                min(v_1_min_pos_acc_at_start, v_1_min_neg_acc_at_end) if \
                        v_1_min_pos_acc_at_start != INF and v_1_min_neg_acc_at_end != INF else \
                (v_1_min_pos_acc_at_start if v_1_min_pos_acc_at_start != INF else \
                v_1_min_neg_acc_at_end)
    else:
        # FIXME: LEFT OFF HERE: Does this need to account for accurate displacement values or anything?
        
        # - From a basic equation of motion:
        #   v = v_0 + a*t
        # - Uses negative acceleration.
        v_1_min = v_0_max - a_magnitude * duration
    
    ### Sanitize the results (remove invalid results, cap values, correct for round-off errors).
    
    # If we found valid v_1_min/v_1_max values, then there must be valid corresponding
    # v_1_min/v_1_max values.
    assert(v_1_max != INF)
    assert(v_1_min != INF)
    assert(v_1_max >= v_1_min)
    
    # Add a small offset to the min and max to help with round-off errors.
    v_1_min += MIN_MAX_VELOCITY_X_OFFSET
    v_1_max -= MIN_MAX_VELOCITY_X_OFFSET
    
    # Correct small floating-point errors around zero.
    if Geometry.are_floats_equal_with_epsilon(v_1_min, 0.0, MIN_MAX_VELOCITY_X_OFFSET * 1.1):
        v_1_min = 0.0
    if Geometry.are_floats_equal_with_epsilon(v_1_max, 0.0, MIN_MAX_VELOCITY_X_OFFSET * 1.1):
        v_1_max = 0.0
    
    if (end_horizontal_movement_sign > 0 and v_1_max < 0) or \
        (end_horizontal_movement_sign < 0 and v_1_min > 0):
        # We cannot reach this constraint with the needed movement direction.
        return []
    
    # Limit velocity to the expected movement direction for this constraint.
    if end_horizontal_movement_sign > 0:
        v_1_min = max(v_1_min, 0.0)
    else:
        v_1_max = min(v_1_max, 0.0)
    
    # Limit max speeds.
    if v_1_min > speed_max or v_1_max < -speed_max:
        # We cannot reach this constraint from the previous constraint.
        return []
    v_1_max = min(v_1_max, speed_max)
    v_1_min = max(v_1_min, -speed_max)
    
    return [v_1_min, v_1_max]

# Accelerating over the whole interval would result in an end velocity that exceeds the max speed.
# So instead, we assume a 2-part movement profile with constant acceleration in the first part and
# constant velocity in the second part. This 2-part movement should more accurately represent
# the limit on v_0.
static func _calculate_v_0_with_v_1_limit(displacement: float, duration: float, v_1: float, \
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

static func _solve_for_end_velocity(displacement: float, duration: float, acceleration: float, \
        v_0: float, should_accelerate_at_start: bool, should_return_min_result: bool) -> float:
    var acceleration_sign := 1 if acceleration >= 0 else -1
    
    var a: float
    var b: float
    var c: float
    
    # FIXME: -------------- REMOVE: DEBUGGING
#    duration = 1.3
    
    # We only need to consider two movement profiles:
    # 
    # - Accelerate at start (2 parts):
    #   - First, constant acceleration to v_1.
    #   - Then, constant velocity at v_1 for the remaining duration.
    # - Accelerate at end (2 parts):
    #   - First, constant velocity at v_0.
    #   - Then, constant acceleration for the remaining duration, ending at v_1.
    # 
    # No other movement profile--e.g., 3-part with constant v at v_0, accelerate to v_1, constant
    # v at v_1--should produce more extreme end velocities, so we only need to consider these two.
    # Any considerations for capping at max-speed will be handled by the consumer function that
    # calls this one.
    
    if should_accelerate_at_start:
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant acceleration from v_0 to v_1.
        #   - Part 2: Coast at v_1 until we reach the destination.
        # - Start with basic equations of motion:
        #   - v_1 = v_0 + a*t_0
        #   - s_2 = s_1 + v_1*t_1
        #   - v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
        #   - t_total = t_0 + t_1
        #   - displacement = s_2 - s_0
        # - Do some algebra...
        #   - 0 = 2*a*displacement + v_0^2 - 2*(a*t_total + v_0)*v_1 + v_1^2
        # - Apply quadratic formula to solve for v_1.
        a = 1
        b = -2 * (acceleration * duration + v_0)
        c = 2 * acceleration * displacement + v_0 * v_0
    else:
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant velocity at v_0.
        #   - Part 2: Constant acceleration for the remaining duration, ending at v_1.
        # - Start with basic equations of motion:
        #   - s_1 = s_0 + v_0*t_0
        #   - v_1 = v_0 + a*t_1
        #   - v_1^2 = v_0^2 + 2*a*(s_2 - s_1)
        #   - t_total = t_0 + t_1
        #   - displacement = s_2 - s_0
        # - Do some algebra...
        #   - 0 = 2*a*(displacement - t_total*v_0) - v_0^2 + 2*v_0*v_1 - v_1^2
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
    
    # From a basic equation of motion:
    #    v = v_0 + a*t
    var t_result_1 := (result_1 - v_0) / acceleration
    var t_result_2 := (result_2 - v_0) / acceleration
    
    ###########################################
    # FIXME: --------------- REMOVE: DEBUGGING
#    var disp_result_1_foo := v_0*t_result_1 + 0.5*acceleration*t_result_1*t_result_1
#    var disp_result_1_bar := result_1*(duration-t_result_1)
#    var disp_result_1_total := disp_result_1_foo + disp_result_1_bar
#    var disp_result_2_foo := v_0*t_result_2 + 0.5*acceleration*t_result_2*t_result_2
#    var disp_result_2_bar := result_2*(duration-t_result_2)
#    var disp_result_2_total := disp_result_2_foo + disp_result_2_bar
    ###########################################
    
    # The results are invalid if they correspond to imaginary negative durations.
    var is_result_1_valid := t_result_1 >= 0 and t_result_1 <= duration
    var is_result_2_valid := t_result_2 >= 0 and t_result_2 <= duration
    
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
        overall_calc_params: MovementCalcOverallParams, \
        vertical_step: MovementVertCalcStep) -> void:
    previous_constraint.next_constraint = constraint
    next_constraint.previous_constraint = constraint
    
    update_constraint(previous_constraint, overall_calc_params.origin_constraint, \
            overall_calc_params.movement_params, vertical_step.velocity_step_start, \
            vertical_step.can_hold_jump_button, vertical_step, Vector2.INF)
    update_constraint(next_constraint, overall_calc_params.origin_constraint, \
            overall_calc_params.movement_params, vertical_step.velocity_step_start, \
            vertical_step.can_hold_jump_button, vertical_step, Vector2.INF)

static func _calculate_replacement_for_fake_constraint(fake_constraint: MovementConstraint, \
        constraint_offset: Vector2) -> MovementConstraint:
    var neighbor_surface: Surface
    var replacement_position := Vector2.INF
    var should_stay_on_min_side: bool
    
    match fake_constraint.surface.side:
        SurfaceSide.FLOOR:
            should_stay_on_min_side = false
            
            if fake_constraint.should_stay_on_min_side:
                # Replacing top-left corner with bottom-left corner.
                neighbor_surface = fake_constraint.surface.convex_counter_clockwise_neighbor
                replacement_position = neighbor_surface.first_point + \
                        Vector2(-constraint_offset.x, constraint_offset.y)
            else:
                # Replacing top-right corner with bottom-right corner.
                neighbor_surface = fake_constraint.surface.convex_clockwise_neighbor
                replacement_position = neighbor_surface.last_point + \
                        Vector2(constraint_offset.x, constraint_offset.y)
        
        SurfaceSide.CEILING:
            should_stay_on_min_side = true
            
            if fake_constraint.should_stay_on_min_side:
                # Replacing bottom-left corner with top-left corner.
                neighbor_surface = fake_constraint.surface.convex_clockwise_neighbor
                replacement_position = neighbor_surface.last_point + \
                        Vector2(-constraint_offset.x, -constraint_offset.y)
            else:
                # Replacing bottom-right corner with top-right corner.
                neighbor_surface = fake_constraint.surface.convex_counter_clockwise_neighbor
                replacement_position = neighbor_surface.first_point + \
                        Vector2(constraint_offset.x, -constraint_offset.y)
        _:
            Utils.error()
    
    var replacement := MovementConstraint.new(neighbor_surface, replacement_position, false, \
            should_stay_on_min_side, fake_constraint.previous_constraint, \
            fake_constraint.next_constraint)
    replacement.replaced_a_fake = true
    return replacement

static func clone_constraint(original: MovementConstraint) -> MovementConstraint:
    var clone := MovementConstraint.new(original.surface, original.position, \
            original.passing_vertically, original.should_stay_on_min_side, \
            original.previous_constraint, original.next_constraint)
    copy_constraint(clone, original)
    return clone

static func copy_constraint(destination: MovementConstraint, \
        source: MovementConstraint) -> MovementConstraint:
    destination.surface = source.surface
    destination.position = source.position
    destination.passing_vertically = source.passing_vertically
    destination.should_stay_on_min_side = source.should_stay_on_min_side
    destination.previous_constraint = source.previous_constraint
    destination.next_constraint = source.next_constraint
    destination.horizontal_movement_sign = source.horizontal_movement_sign
    destination.horizontal_movement_sign_from_displacement = \
            source.horizontal_movement_sign_from_displacement
    destination.time_passing_through = source.time_passing_through
    destination.min_velocity_x = source.min_velocity_x
    destination.max_velocity_x = source.max_velocity_x
    destination.actual_velocity_x = source.actual_velocity_x
    destination.is_origin = source.is_origin
    destination.is_destination = source.is_destination
    destination.is_fake = source.is_fake
    destination.is_valid = source.is_valid
    destination.replaced_a_fake = source.replaced_a_fake
    return destination
