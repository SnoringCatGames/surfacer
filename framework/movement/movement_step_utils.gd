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
static func calculate_steps_with_new_jump_height(overall_calc_params: MovementCalcOverallParams, \
        parent_step_calc_params: MovementCalcStepParams, \
        previous_out_of_reach_constraint: MovementConstraint) -> MovementCalcResults:
    var vertical_step := VerticalMovementUtils.calculate_vertical_step(overall_calc_params)
    if vertical_step == null:
        # The destination is out of reach.
        return null
    
    var step_calc_params := MovementCalcStepParams.new(overall_calc_params.origin_constraint, \
            overall_calc_params.destination_constraint, vertical_step, overall_calc_params, \
            parent_step_calc_params, previous_out_of_reach_constraint)
    
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
    
    if next_horizontal_step == null:
        # The destination is out of reach.
        step_calc_params.debug_state.result_code = EdgeStepCalcResult.TARGET_OUT_OF_REACH
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
    
    # FIXME: DEBUGGING: REMOVE:
#    if step_calc_params.start_constraint.position == Vector2(106, 37.5):
#        print("break")
    
    var collision := CollisionCheckUtils.check_continuous_horizontal_step_for_collision( \
            overall_calc_params, step_calc_params, next_horizontal_step)
    
    if collision != null and !collision.is_valid_collision_state:
        # An error occured during collision detection, so we abandon this step calculation.
        return null
    
    if collision == null or \
            (collision.surface == overall_calc_params.destination_constraint.surface):
        # There is no intermediate surface interfering with this movement.
        step_calc_params.debug_state.result_code = EdgeStepCalcResult.MOVEMENT_VALID
        return MovementCalcResults.new([next_horizontal_step], vertical_step)
    
    ### RECURSIVE CASES
    
    # Calculate possible constraints to divert the movement around either side of the colliding
    # surface.
    var constraints := MovementConstraintUtils.calculate_constraints_around_surface( \
            overall_calc_params.movement_params, vertical_step, \
            step_calc_params.start_constraint, step_calc_params.end_constraint, \
            overall_calc_params.origin_constraint, overall_calc_params.destination_constraint, \
            collision.surface, overall_calc_params.constraint_offset)
    step_calc_params.debug_state.upcoming_constraints = constraints
    
    # First, try to satisfy the constraints without backtracking to consider a new max jump height.
    var calc_results := calculate_steps_from_constraint_without_backtracking_on_height( \
            overall_calc_params, step_calc_params, constraints)
    if calc_results != null or !overall_calc_params.can_backtrack_on_height:
        # Recursion was successful without backtracking for a new max jump height.
        step_calc_params.debug_state.result_code = EdgeStepCalcResult.RECURSION_VALID
        return calc_results
    
    if overall_calc_params.is_backtracking_valid_for_surface(collision.surface, \
            vertical_step.time_instruction_end):
        # We've already tried backtracking for a collision with this surface, so this movement
        # won't work. Without this check, we'd recurse through a traversal branch that is identical
        # to one we've already considered, and we'd loop infinitely.
        step_calc_params.debug_state.result_code = EdgeStepCalcResult.ALREADY_BACKTRACKED_FOR_SURFACE
        return null
    
    overall_calc_params.record_backtracked_surface(collision.surface, \
            vertical_step.time_instruction_end)
    
    # Then, try to satisfy the constraints with backtracking to consider a new max jump height.
    calc_results = calculate_steps_from_constraint_with_backtracking_on_height( \
            overall_calc_params, step_calc_params, constraints)
    if calc_results != null:
        # Recursion was successful with backtracking for a new max jump height.
        step_calc_params.debug_state.result_code = EdgeStepCalcResult.BACKTRACKING_VALID
    else:
        # Recursion was not successful, despite backtracking for a new max jump height.
        step_calc_params.debug_state.result_code = EdgeStepCalcResult.BACKTRACKING_INVALID
    return calc_results

# Check whether either constraint can be satisfied with our current max jump height.
static func calculate_steps_from_constraint_without_backtracking_on_height( \
        overall_calc_params: MovementCalcOverallParams, \
        step_calc_params: MovementCalcStepParams, constraints: Array) -> MovementCalcResults:
    var vertical_step := step_calc_params.vertical_step
    var previous_constraint_original := step_calc_params.start_constraint
    var next_constraint_original := step_calc_params.end_constraint
    
    var previous_constraint_copy: MovementConstraint
    var next_constraint_copy: MovementConstraint
    var step_calc_params_to_constraint: MovementCalcStepParams
    var step_calc_params_from_constraint: MovementCalcStepParams
    var calc_results_to_constraint: MovementCalcResults
    var calc_results_from_constraint: MovementCalcResults
    
    var result: MovementCalcResults
    
    for constraint in constraints:
        if !constraint.is_valid:
            # This constraint is out of reach.
            continue
        
        # Make copies of the previous and next constraints. We don't want to update the originals,
        # unless we know the recursion was successful,
        # in case this recursion fails.
        previous_constraint_copy = \
                MovementConstraintUtils.clone_constraint(previous_constraint_original)
        next_constraint_copy = MovementConstraintUtils.clone_constraint(next_constraint_original)
        
        # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE:
#        if Geometry.are_points_equal_with_epsilon( \
#                constraint.position, \
#                Vector2(64, -480), 10):
#            print("break")
        
        # FIXME: B: Verify this statement.
        
        # Update the previous and next constraints, to account for this new intermediate
        # constraint. These updates do not solve all cases, since we may in turn need to update the
        # min/max/actual x-velocities and movement sign for all other constraints. And these
        # updates could then result in the addition/removal of other intermediate constraints.
        # But we have found that these two updates are enough for most cases.
        MovementConstraintUtils.update_neighbors_for_new_constraint(constraint, \
                previous_constraint_copy, next_constraint_copy, overall_calc_params, \
                vertical_step)
        if !previous_constraint_copy.is_valid or !next_constraint_copy.is_valid:
            continue
        
        ### RECURSE: Calculate movement to the constraint.
        
        step_calc_params_to_constraint = MovementCalcStepParams.new(previous_constraint_copy, \
                constraint, vertical_step, overall_calc_params, step_calc_params, null)
        calc_results_to_constraint = calculate_steps_from_constraint(overall_calc_params, \
                step_calc_params_to_constraint)
        
        if calc_results_to_constraint == null:
            # This constraint is out of reach with the current jump height.
            continue
        
        if calc_results_to_constraint.backtracked_for_new_jump_height:
            # When backtracking occurs, the result includes all steps from origin to destination,
            # so we can just return that result here.
            result = calc_results_to_constraint
            break
        
        ### RECURSE: Calculate movement from the constraint to the original destination.
        
        step_calc_params_from_constraint = MovementCalcStepParams.new(constraint, \
                next_constraint_copy, vertical_step, overall_calc_params, step_calc_params, null)
        calc_results_from_constraint = calculate_steps_from_constraint(overall_calc_params, \
                step_calc_params_from_constraint)
        
        if calc_results_from_constraint == null:
            # This constraint is out of reach with the current jump height.
            continue
        
        if calc_results_from_constraint.backtracked_for_new_jump_height:
            # When backtracking occurs, the result includes all steps from origin to destination,
            # so we can just return that result here.
            result = calc_results_from_constraint
            break
        
        # We found movement that satisfies the constraint (without backtracking for a new jump
        # height).
        Utils.concat(calc_results_to_constraint.horizontal_steps, \
                calc_results_from_constraint.horizontal_steps)
        result = calc_results_to_constraint
        break
    
    if result != null:
        # Update the original constraints to match the state for this successful navigation.
        MovementConstraintUtils.copy_constraint(previous_constraint_original, \
                previous_constraint_copy)
        MovementConstraintUtils.copy_constraint(next_constraint_original, next_constraint_copy)
    return result

# Check whether either constraint can be satisfied if we backtrack to re-calculate the initial
# vertical step with a higher max jump height.
static func calculate_steps_from_constraint_with_backtracking_on_height( \
        overall_calc_params: MovementCalcOverallParams, \
        step_calc_params: MovementCalcStepParams, constraints: Array) -> MovementCalcResults:
    var destination_original := overall_calc_params.destination_constraint
    var destination_copy: MovementConstraint
    var calc_results: MovementCalcResults
    
    var result: MovementCalcResults
    
    for constraint in constraints:
        if constraint.is_valid:
            # This constraint was already in reach, so we don't need to try increasing jump height
            # for it.
            continue
        
        # Make a copy of the destination constraint. We don't want to update the original, unless
        # we know the backtracking succeeded.
        destination_copy = MovementConstraintUtils.clone_constraint(destination_original)
        overall_calc_params.destination_constraint = destination_copy
        
        # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE:
#        if step_calc_params.debug_state.index == 5:
#            print("break")
        
        # Update the destination constraint to support a (possibly) increased jump height, which
        # would enable movement through this new intermediate constraint.
        MovementConstraintUtils.update_constraint(destination_copy, \
                overall_calc_params.origin_constraint, overall_calc_params.movement_params, \
                step_calc_params.vertical_step.velocity_step_start, true, \
                step_calc_params.vertical_step, constraint.position)
        if !destination_copy.is_valid:
            # The constraint is out of reach.
            continue
        
        # Recurse: Backtrack and try a higher jump (to the same destination constraint as before).
        calc_results = calculate_steps_with_new_jump_height( \
                overall_calc_params, step_calc_params, constraint)
        
        if calc_results != null:
            # The constraint is within reach, and we were able to find valid movement steps to the
            # destination.
            calc_results.backtracked_for_new_jump_height = true
            result = calc_results
            break
    
    if result != null:
        # Update the original destination constraint to match the state for this successful
        # navigation.
        MovementConstraintUtils.copy_constraint(destination_original, destination_copy)
    overall_calc_params.destination_constraint = destination_original
    return result
