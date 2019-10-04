# A collection of utility functions for calculating state related to MovementCalcSteps.
class_name MovementStepUtils

const MovementCalcStepParams := preload("res://framework/movement/models/movement_calculation_step_params.gd")

# Calculates movement steps to reach the given destination.
# 
# This first calculates the one vertical step of the overall movement, using the minimum possible
# peak jump height. It then calculates the horizontal steps.
# 
# This can trigger recursive calls if horizontal movement cannot be satisfied without backtracking
# to consider a new higher jump height.
static func calculate_steps_with_new_jump_height( \
        overall_calc_params: MovementCalcOverallParams) -> MovementCalcResults:
    var vertical_step := VerticalMovementUtils.calculate_vertical_step(overall_calc_params)
    if vertical_step == null:
        # The destination is out of reach.
        return null
    
    var step_calc_params := MovementCalcStepParams.new(overall_calc_params, \
            overall_calc_params.origin_constraint, overall_calc_params.destination_constraint, \
            vertical_step)
    
    return calculate_steps_from_constraint(overall_calc_params, step_calc_params)

# Recursively calculates a list of movement steps to reach the given destination.
# 
# Normally, this function deals with horizontal movement steps. However, if we find that a
# constraint cannot be satisfied with just horizontal movement, we may backtrack and try a new
# recursive traversal using a higher jump height.
static func calculate_steps_from_constraint(overall_calc_params: MovementCalcOverallParams, \
        step_calc_params: MovementCalcStepParams) -> MovementCalcResults:
    ### BASE CASES
    
    var next_horizontal_step := HorizontalMovementUtils.calculate_horizontal_step( \
            step_calc_params, overall_calc_params)
    
    # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE: -A:
    # - Debugging min step-end velocity.
    # - Get the up-left jump from floor to floor working on level long-rise.
    # - Set a breakpoint here.
    print("yo")
    
    if next_horizontal_step == null:
        # The destination is out of reach.
        return null
    
    var vertical_step := step_calc_params.vertical_step
    
    # If this is the last horizontal step, then let's check whether whether we calculated
    # things correctly.
    if step_calc_params.end_constraint.is_destination:
        assert(Geometry.are_floats_equal_with_epsilon( \
                next_horizontal_step.time_step_end, vertical_step.time_step_end, 0.0001))
        assert(Geometry.are_floats_equal_with_epsilon( \
                next_horizontal_step.position_step_end.y, vertical_step.position_step_end.y, \
                0.001))
        assert(Geometry.are_points_equal_with_epsilon(next_horizontal_step.position_step_end, \
                overall_calc_params.destination_constraint.position, 0.0001))
    
    var collision := CollisionCheckUtils.check_continuous_horizontal_step_for_collision( \
            overall_calc_params, step_calc_params, next_horizontal_step)
    
    # We expect that temporary, fake constraints will always have a corresponding following
    # collision, since we need to replace these with one of the real constraints from this
    # collision.
    # FIXME: B: Should this instead be an if statement that returns null? How likely is this to
    #           happen for valid movement?
    assert(!step_calc_params.start_constraint.is_fake or \
            (collision != null and \
                    (collision.surface.side == SurfaceSide.LEFT_WALL or \
                    collision.surface.side == SurfaceSide.RIGHT_WALL)))
    
    if collision == null or collision.surface == overall_calc_params.destination_constraint.surface:
        # There is no intermediate surface interfering with this movement.
        return MovementCalcResults.new([next_horizontal_step], vertical_step, \
                step_calc_params.start_constraint)
    
    ### RECURSIVE CASES
    
    var previous_constraint := step_calc_params.previous_constraint_if_start_is_fake if \
            step_calc_params.start_constraint.is_fake else step_calc_params.start_constraint
    
    # Calculate possible constraints to divert the movement around either side of the colliding
    # surface.
    var constraints := MovementConstraintUtils.calculate_constraints_around_surface( \
            overall_calc_params.movement_params, vertical_step, \
            previous_constraint, overall_calc_params.origin_constraint, \
            collision.surface, overall_calc_params.constraint_offset)
    if constraints.empty():
        return null
    
    if step_calc_params.start_constraint.is_fake:
        # Only one of the possible constraints from the collision can be valid, depending on
        # whether the fake constraint was from a floor or a ceiling.
        
        var fake_constraint_surface_side := step_calc_params.start_constraint.surface.side
        
        # We expect that fake constraints will only be created for floor or ceiling surfaces.
        assert(fake_constraint_surface_side == SurfaceSide.FLOOR or \
                fake_constraint_surface_side == SurfaceSide.CEILING)
        
        var should_ignore_min_side_constraint := \
                fake_constraint_surface_side == SurfaceSide.FLOOR
        
        # Remove the invalid constraint according to the surface side.
        if constraints[0].should_stay_on_min_side == should_ignore_min_side_constraint:
            constraints.remove(0)
        elif constraints.size() > 1 and \
                constraints[1].should_stay_on_min_side == should_ignore_min_side_constraint:
            constraints.remove(1)
        
        if constraints.empty():
            return null
    
    # First, try to satisfy the constraints without backtracking to consider a new max jump height.
    var calc_results := calculate_steps_from_constraint_without_backtracking_on_height( \
            overall_calc_params, step_calc_params, constraints)
    if calc_results != null or !overall_calc_params.can_backtrack_on_height:
        return calc_results
    
    if overall_calc_params.collided_surfaces.has(collision.surface):
        # We've already tried backtracking for a collision with this surface, so this movement
        # won't work. Without this check, we'd recurse through a traversal branch that is identical
        # to one we've already considered, and we'd loop infinitely.
        return null
    
    overall_calc_params.collided_surfaces[collision.surface] = true
    
    # Then, try to satisfy the constraints with backtracking to consider a new max jump height.
    return calculate_steps_from_constraint_with_backtracking_on_height( \
            overall_calc_params, step_calc_params, constraints)

# Check whether either constraint can be satisfied with our current max jump height.
static func calculate_steps_from_constraint_without_backtracking_on_height( \
        overall_calc_params: MovementCalcOverallParams, \
        step_calc_params: MovementCalcStepParams, constraints: Array) -> MovementCalcResults:
    var vertical_step := step_calc_params.vertical_step
    var is_start_constraint_fake := step_calc_params.start_constraint.is_fake
    var previous_constraint_original := step_calc_params.previous_constraint_if_start_is_fake if \
            is_start_constraint_fake else step_calc_params.start_constraint
    var next_constraint_original := step_calc_params.end_constraint
    
    var previous_constraint_copy: MovementConstraint
    var next_constraint_copy: MovementConstraint
    var step_calc_params_to_constraint: MovementCalcStepParams
    var step_calc_params_from_constraint: MovementCalcStepParams
    var calc_results_to_constraint: MovementCalcResults
    var calc_results_from_constraint: MovementCalcResults
    
    # FIXME: B: Add heuristics to pick the "better" constraint first.
    
    for constraint in constraints:
        # Calculate steps in reverse order in order to ensure that each step ends with a certain x
        # velocity.
        
        # Make copies of the previous and next constraints. We don't want to update the originals,
        # in case this recursion fails.
        previous_constraint_copy = \
                MovementConstraintUtils.copy_constraint(previous_constraint_original)
        next_constraint_copy = MovementConstraintUtils.copy_constraint(next_constraint_original)
        
        # FIXME: LEFT OFF HERE: A: Verify this statement.
        
        # Update the previous and next constraints, to account for this new intermediate
        # constraint. These updates are not completely sufficient, since we may in turn need to
        # update the min/max/actual x-velocities and movement sign for all other constraints. And
        # these updates could then result in the addition/removal of other intermediate
        # constraints. But we have found that these two updates are enough for most cases.
        MovementConstraintUtils.update_neighbors_for_new_constraint(constraint, \
                previous_constraint_copy, next_constraint_copy, overall_calc_params, \
                vertical_step)
        
        ### RECURSE: Calculate movement from the constraint to the original destination.
        
        step_calc_params_from_constraint = MovementCalcStepParams.new(overall_calc_params, \
                constraint, next_constraint_copy, vertical_step)
        if constraint.is_fake:
            # If the start constraint is fake, then we will need access to the latest real
            # constraint.
            step_calc_params_from_constraint.previous_constraint_if_start_is_fake = \
                    previous_constraint_copy
        calc_results_from_constraint = calculate_steps_from_constraint(overall_calc_params, \
                step_calc_params_from_constraint)
        
        if calc_results_from_constraint == null:
            # This constraint is out of reach with the current jump height.
            continue
        
        if constraint.is_fake:
            # We should have found a very close-by collision with a neighboring surface. We replace
            # the fake/temporary constraint with this.
            constraint = calc_results_from_constraint.start_constraint
            # calculate_steps_from_constraint shouldn't return the same fake constraint, and there
            # shouldn't be two fake constraints in a row.
            assert(!constraint.is_fake)
        
        if calc_results_from_constraint.backtracked_for_new_jump_height:
            # When backtracking occurs, the result includes all steps from origin to destination,
            # so we can just return that result here.
            return calc_results_from_constraint
        
        if is_start_constraint_fake:
            # Since we're skipping the fake constraint, we don't need to calculate steps from it.
            # Steps leading up to this new post-fake-constraint will be calculated from one-layer
            # up in the recursion tree.
            calc_results_from_constraint.start_constraint = constraint
            return calc_results_from_constraint
        
        ### RECURSE: Calculate movement to the constraint.
        
        step_calc_params_to_constraint = MovementCalcStepParams.new(overall_calc_params, \
                previous_constraint_copy, constraint, vertical_step)
        calc_results_to_constraint = calculate_steps_from_constraint(overall_calc_params, \
                step_calc_params_to_constraint)
        
        if calc_results_to_constraint == null:
            # This constraint is out of reach with the current jump height.
            continue
        
        if calc_results_to_constraint.backtracked_for_new_jump_height:
            # When backtracking occurs, the result includes all steps from origin to destination,
            # so we can just return that result here.
            return calc_results_to_constraint
        
        # We found movement that satisfies the constraint (without backtracking for a new jump
        # height).
        Utils.concat(calc_results_to_constraint.horizontal_steps, \
                calc_results_from_constraint.horizontal_steps)
        return calc_results_to_constraint
    
    # We weren't able to satisfy the constraints around the colliding surface.
    if is_start_constraint_fake:
        step_calc_params.previous_constraint_if_start_is_fake = previous_constraint_original
    else:
        step_calc_params.start_constraint = previous_constraint_original
    step_calc_params.end_constraint = next_constraint_original
    return null

# Check whether either constraint can be satisfied if we backtrack to re-calculate the initial
# vertical step with a higher max jump height.
static func calculate_steps_from_constraint_with_backtracking_on_height( \
        overall_calc_params: MovementCalcOverallParams, \
        step_calc_params: MovementCalcStepParams, constraints: Array) -> MovementCalcResults:
    var destination_original := overall_calc_params.destination_constraint
    var destination_copy: MovementConstraint
    var is_constraint_valid: bool
    var calc_results: MovementCalcResults
    
    # FIXME: B: Add heuristics to pick the "better" constraint first.
    
    for constraint in constraints:
        # Make a copy of the destination constraint. We don't want to update the original, in case
        # this backtracking fails.
        destination_copy = MovementConstraintUtils.copy_constraint(destination_original)
        overall_calc_params.destination_constraint = destination_copy

        # Update the destination constraint to support a (possibly) increased jump height, which
        # would enable movement through this new intermediate constraint.
        is_constraint_valid = MovementConstraintUtils.update_constraint(destination_copy, \
                overall_calc_params.origin_constraint, null, overall_calc_params.origin_constraint, \
                overall_calc_params.movement_params, overall_calc_params.constraint_offset, \
                step_calc_params.vertical_step.velocity_step_start, true, \
                step_calc_params.vertical_step, constraint)
        if !is_constraint_valid:
            # The constraint is out of reach.
            continue

        # Recurse: Backtrack and try a higher jump (to the constraint).
        calc_results = calculate_steps_with_new_jump_height(overall_calc_params)
        if calc_results != null:
            # The constraint is within reach, and we were able to find valid movement steps to the
            # destination.
            calc_results.backtracked_for_new_jump_height = true
            return calc_results
    
    # We weren't able to satisfy the constraints around the colliding surface.
    overall_calc_params.destination_constraint = destination_original
    return null
