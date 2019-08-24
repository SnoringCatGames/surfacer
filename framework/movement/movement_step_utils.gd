# A collection of utility functions for calculating state related to MovementCalcSteps.
class_name MovementStepUtils

const MovementCalcLocalParams := preload("res://framework/movement/models/movement_calculation_local_params.gd")

# Calculates movement steps to reach the given destination.
# 
# This first calculates the one vertical step of the overall movement, using the minimum possible
# peak jump height. It then calculates the horizontal steps.
# 
# This can trigger recursive calls if horizontal movement cannot be satisfied without backtracking
# to consider a new higher jump height.
static func calculate_steps_with_new_jump_height( \
        global_calc_params: MovementCalcGlobalParams) -> MovementCalcResults:
    var vertical_step := VerticalMovementUtils.calculate_vertical_step(global_calc_params)
    if vertical_step == null:
        # The destination is out of reach.
        return null
    
    var local_calc_params := MovementCalcLocalParams.new(global_calc_params.origin_constraint, \
            global_calc_params.destination_constraint, vertical_step)
    
    return calculate_steps_from_constraint(global_calc_params, local_calc_params)

# Recursively calculates a list of movement steps to reach the given destination.
# 
# Normally, this function deals with horizontal movement steps. However, if we find that a
# constraint cannot be satisfied with just horizontal movement, we may backtrack and try a new
# recursive traversal using a higher jump height.
static func calculate_steps_from_constraint(global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams) -> MovementCalcResults:
    ### BASE CASES
    
    var next_horizontal_step := HorizontalMovementUtils.calculate_horizontal_step( \
            local_calc_params, global_calc_params)
    
    # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE: -A:
    # - Debugging min step-end velocity.
    # - Get the up-left jump from floor to floor working on level long-rise.
    # - Set a breakpoint here.
#    print("yo")
    
    if next_horizontal_step == null:
        # The destination is out of reach.
        return null
    
    var vertical_step := local_calc_params.vertical_step
    
    # If this is the last horizontal step, then let's check whether whether we calculated
    # things correctly.
    if local_calc_params.end_constraint.is_destination:
        assert(Geometry.are_floats_equal_with_epsilon( \
                next_horizontal_step.time_step_end, vertical_step.time_step_end, 0.0001))
        assert(Geometry.are_floats_equal_with_epsilon( \
                next_horizontal_step.position_step_end.y, vertical_step.position_step_end.y, \
                0.001))
        assert(Geometry.are_points_equal_with_epsilon(next_horizontal_step.position_step_end, \
                global_calc_params.destination_constraint.position, 0.0001))
    
    var collision := CollisionCheckUtils.check_continuous_horizontal_step_for_collision( \
            global_calc_params, local_calc_params, next_horizontal_step)
    
    if collision == null or collision.surface == global_calc_params.destination_constraint.surface:
        # There is no intermediate surface interfering with this movement.
        return MovementCalcResults.new([next_horizontal_step], vertical_step)
    
    if global_calc_params.collided_surfaces.has(collision.surface):
        # We've already considered a collision with this surface, so this movement won't work.
        # Without this check, we'd recurse through a traversal branch that is identical to one
        # we've already considered, and we'd loop infinitely.
        return null
    
    ### RECURSIVE CASES
    
    global_calc_params.collided_surfaces[collision.surface] = true
    
    # Calculate possible constraints to divert the movement around either side of the colliding
    # surface.
    var constraints := MovementConstraintUtils.calculate_constraints_around_surface( \
            global_calc_params.movement_params, vertical_step, \
            local_calc_params.start_constraint, global_calc_params.origin_constraint, \
            collision.surface, global_calc_params.constraint_offset)
    if constraints.empty():
        return null
    
    # First, try to satisfy the constraints without backtracking to consider a new max jump height.
    var calc_results := calculate_steps_from_constraint_without_backtracking_on_height( \
            global_calc_params, local_calc_params, constraints)
    if calc_results != null or !global_calc_params.can_backtrack_on_height:
        return calc_results
    
    # Then, try to satisfy the constraints with backtracking to consider a new max jump height.
    return calculate_steps_from_constraint_with_backtracking_on_height( \
            global_calc_params, local_calc_params, constraints)

# Check whether either constraint can be satisfied with our current max jump height.
static func calculate_steps_from_constraint_without_backtracking_on_height( \
        global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams, constraints: Array) -> MovementCalcResults:
    var previous_constraint_original := local_calc_params.start_constraint
    var next_constraint_original := local_calc_params.end_constraint
    var previous_constraint_copy: MovementConstraint
    var next_constraint_copy: MovementConstraint
    var local_calc_params_to_constraint: MovementCalcLocalParams
    var local_calc_params_from_constraint: MovementCalcLocalParams
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
        local_calc_params.start_constraint = previous_constraint_copy
        next_constraint_copy = MovementConstraintUtils.copy_constraint(next_constraint_original)
        local_calc_params.end_constraint = next_constraint_copy

        # FIXME: LEFT OFF HERE: A: Verify this statement.

        # Update the previous and next constraints, to account for this new intermediate
        # constraint. These updates are not completely sufficient, since we may in turn need to
        # update the min/max/actual x-velocities and movement sign for all other constraints. And
        # these updates could then result in the addition/removal of other intermediate
        # constraints. But we have found that these two updates are enough for most cases.
        MovementConstraintUtils.update_neighbors_for_new_constraint(constraint, \
                previous_constraint_copy, next_constraint_copy, global_calc_params, \
                local_calc_params.vertical_step)

        ### RECURSE: Calculate movement from the constraint to the original destination.

        local_calc_params_from_constraint = MovementCalcLocalParams.new( \
                constraint, local_calc_params.end_constraint, \
                local_calc_params.vertical_step)
        calc_results_from_constraint = calculate_steps_from_constraint(global_calc_params, \
                local_calc_params_from_constraint)
        
        if calc_results_from_constraint == null:
            # This constraint is out of reach with the current jump height.
            continue
        
        if calc_results_from_constraint.backtracked_for_new_jump_height:
            # When backtracking occurs, the result includes all steps from origin to destination,
            # so we can just return that result here.
            return calc_results_from_constraint
        
        ### RECURSE: Calculate movement to the constraint.

        local_calc_params_to_constraint = MovementCalcLocalParams.new( \
                local_calc_params.start_constraint, constraint, \
                local_calc_params.vertical_step)
        calc_results_to_constraint = calculate_steps_from_constraint(global_calc_params, \
                local_calc_params_to_constraint)
        
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
    local_calc_params.start_constraint = previous_constraint_original
    local_calc_params.end_constraint = next_constraint_original
    return null

# Check whether either constraint can be satisfied if we backtrack to re-calculate the initial
# vertical step with a higher max jump height.
static func calculate_steps_from_constraint_with_backtracking_on_height( \
        global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams, constraints: Array) -> MovementCalcResults:
    var destination_original := global_calc_params.destination_constraint
    var destination_copy: MovementConstraint
    var is_constraint_valid: bool
    var calc_results: MovementCalcResults
    
    # FIXME: B: Add heuristics to pick the "better" constraint first.
    
    for constraint in constraints:
        # Make a copy of the destination constraint. We don't want to update the original, in case
        # this backtracking fails.
        destination_copy = MovementConstraintUtils.copy_constraint(destination_original)
        global_calc_params.destination_constraint = destination_copy

        # Update the destination constraint to support a (possibly) increased jump height, which
        # would enable movement through this new intermediate constraint.
        is_constraint_valid = MovementConstraintUtils.update_constraint(destination_copy, \
                global_calc_params.origin_constraint, null, global_calc_params.origin_constraint, \
                global_calc_params.movement_params, \
                global_calc_params.origin_constraint.velocity_start, true, \
                local_calc_params.vertical_step, constraint)
        if !is_constraint_valid:
            # The constraint is out of reach.
            continue

        # Recurse: Backtrack and try a higher jump (to the constraint).
        calc_results = calculate_steps_with_new_jump_height(global_calc_params)
        if calc_results != null:
            # The constraint is within reach, and we were able to find valid movement steps to the
            # destination.
            calc_results.backtracked_for_new_jump_height = true
            return calc_results
    
    # We weren't able to satisfy the constraints around the colliding surface.
    global_calc_params.destination_constraint = destination_original
    return null
