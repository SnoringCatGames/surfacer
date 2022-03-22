class_name EdgeStepUtils
extends Reference
# A collection of utility functions for calculating state related to
# MovementCalcSteps.


# Calculates movement steps to reach the given destination.
# 
# This first calculates the one vertical step of the overall movement, using
# the minimum possible peak jump height. It then calculates the horizontal
# steps.
# 
# This can trigger recursive calls if horizontal movement cannot be satisfied
# without backtracking to consider a new higher jump height.
static func calculate_steps_with_new_jump_height(
        edge_result_metadata: EdgeCalcResultMetadata,
        edge_calc_params: EdgeCalcParams,
        parent_step_result_metadata = null,
        previous_out_of_reach_waypoint = null) -> EdgeCalcResult:
    var vertical_step := VerticalMovementUtils.calculate_vertical_step(
            edge_result_metadata,
            edge_calc_params)
    if vertical_step == null:
        # The destination is out of reach.
        return null
    
    var step_calc_params := EdgeStepCalcParams.new(
            edge_calc_params.origin_waypoint,
            edge_calc_params.destination_waypoint,
            vertical_step)
    
    var step_result_metadata: EdgeStepCalcResultMetadata
    if edge_result_metadata.records_calc_details:
        step_result_metadata = EdgeStepCalcResultMetadata.new(
                edge_result_metadata,
                parent_step_result_metadata,
                step_calc_params,
                previous_out_of_reach_waypoint)
    
    var calc_result := calculate_steps_between_waypoints(
            edge_result_metadata,
            step_result_metadata,
            edge_calc_params,
            step_calc_params)
    
    edge_result_metadata.edge_calc_result_type = \
            EdgeCalcResultType.FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS if \
            calc_result == null else \
            (EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP if \
            calc_result.horizontal_steps.size() == 1 and \
                    !calc_result.increased_jump_height else \
            (EdgeCalcResultType.EDGE_VALID_WITH_INCREASING_JUMP_HEIGHT if \
            calc_result.increased_jump_height else \
            EdgeCalcResultType.EDGE_VALID_WITHOUT_INCREASING_JUMP_HEIGHT))
    if calc_result != null:
        calc_result.edge_calc_result_type = \
                edge_result_metadata.edge_calc_result_type
    
    return calc_result


# Recursively calculates a list of movement steps to reach the given
# destination.
# 
# Normally, this function deals with horizontal movement steps. However, if we
# find that a waypoint cannot be satisfied with just horizontal movement, we
# may backtrack and try a new recursive traversal using a higher jump height.
static func calculate_steps_between_waypoints(
        edge_result_metadata: EdgeCalcResultMetadata,
        step_result_metadata: EdgeStepCalcResultMetadata,
        edge_calc_params: EdgeCalcParams,
        step_calc_params: EdgeStepCalcParams) -> EdgeCalcResult:
    ### BASE CASES
    
    var next_horizontal_step := \
            HorizontalMovementUtils.calculate_horizontal_step(
                    edge_result_metadata,
                    step_calc_params,
                    edge_calc_params)
    
    if step_result_metadata != null:
        step_result_metadata.step = next_horizontal_step
    
    if next_horizontal_step == null:
        # The destination is out of reach.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.TARGET_OUT_OF_REACH
        return null
    
    var vertical_step := step_calc_params.vertical_step
    
    # If this is the last horizontal step, then let's check whether whether we
    # calculated things correctly.
    if step_calc_params.end_waypoint.is_destination:
        assert(Sc.geometry.are_floats_equal_with_epsilon(
                next_horizontal_step.time_step_end,
                vertical_step.time_step_end,
                0.0001))
        assert(Sc.geometry.are_floats_equal_with_epsilon(
                next_horizontal_step.position_step_end.y,
                vertical_step.position_step_end.y,
                0.001))
        assert(Sc.geometry.are_points_equal_with_epsilon(
                next_horizontal_step.position_step_end,
                edge_calc_params.destination_waypoint.position,
                0.0001))
    
    var collision := CollisionCheckUtils \
            .check_continuous_horizontal_step_for_collision(
                    step_result_metadata,
                    edge_calc_params,
                    step_calc_params,
                    next_horizontal_step)
    
    if collision != null and \
            !collision.is_valid_collision_state:
        # An error occured during collision detection, so we abandon this step
        # calculation.
        Sc.profiler.increment_count(
                "invalid_collision_state_in_calculate_steps_between_waypoints",
                edge_calc_params.collision_params.thread_id,
                edge_result_metadata)
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.INVALID_COLLISON_STATE
        return null
    
    if collision == null or \
            (collision.surface == \
            edge_calc_params.destination_waypoint.surface):
        # There is no intermediate surface interfering with this movement.
        
        var frame_count := next_horizontal_step.frame_positions.size()
        
        if frame_count < edge_calc_params.movement_params \
                .min_frame_count_when_colliding_early_with_expected_surface:
            # Hit the expected surface too early.
            if step_result_metadata != null:
                step_result_metadata.edge_step_calc_result_type = \
                        EdgeStepCalcResultType\
                                .EXPECTED_SURFACE_BUT_TOO_FEW_FRAMES
            return null
            
        else:
            if step_result_metadata != null:
                step_result_metadata.edge_step_calc_result_type = \
                        EdgeStepCalcResultType.MOVEMENT_VALID
            var result := EdgeCalcResult.new(
                    [next_horizontal_step],
                    vertical_step,
                    edge_calc_params)
            if collision != null:
                result.collision_time = \
                        next_horizontal_step.time_step_start + \
                        (frame_count - 1) * ScaffolderTime.PHYSICS_TIME_STEP + \
                        collision.time_from_start_of_frame
            return result
    
    if collision.surface == step_calc_params.end_waypoint.surface:
        # -   We are in a recursive step and colliding with the same surface as
        #     the parent step.
        # -   This should only happen when the edge-calculation is trying to
        #     move around a surface that has more than two vertices, and a
        #     middle vertex sticks out further, in the normal direction, than
        #     the end vertices, so, even though we are trying to navigate
        #     around the ends of the surface, we still collide with the center.
        # -   In that case, the parent step should have actually calculated
        #     three waypoints, and one of the other recursive child step calls
        #     may be able to successfully move around the surface.
        # -   Regardless, we don't want to redundantly consider waypoints
        #     around the same surface again here.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.REDUNDANT_RECURSIVE_COLLISION
        return null
    
    Sc.profiler.increment_count(
            "collision_in_calculate_steps_between_waypoints",
            edge_calc_params.collision_params.thread_id,
            edge_result_metadata)
    
    ### RECURSIVE CASES
    
    if !edge_calc_params.movement_params \
            .recurses_when_colliding_during_horizontal_step_calculations:
        # This character is configured to abandon any step recursion for
        # intermediate collisions.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.CONFIGURED_TO_SKIP_RECURSION
        return null
    
    # Calculate possible waypoints to divert the movement around either side of
    # the colliding surface.
    var waypoints := WaypointUtils.calculate_waypoints_around_surface(
            edge_result_metadata,
            edge_calc_params.collision_params,
            edge_calc_params.movement_params,
            vertical_step,
            step_calc_params.start_waypoint,
            step_calc_params.end_waypoint,
            edge_calc_params.origin_waypoint,
            edge_calc_params.destination_waypoint,
            collision.surface,
            edge_calc_params.waypoint_offset)
    if step_result_metadata != null:
        step_result_metadata.upcoming_waypoints = waypoints
    
    # First, try to satisfy the waypoints without backtracking to consider a
    # new max jump height.
    var calc_result := \
            calculate_steps_between_waypoints_without_backtracking_on_height(
                    edge_result_metadata,
                    step_result_metadata,
                    edge_calc_params,
                    step_calc_params,
                    waypoints)
    if calc_result != null:
        # Recursion was successful without backtracking for a new max jump
        # height.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.RECURSION_VALID
        return calc_result
    
    if !edge_calc_params.can_backtrack_on_height:
        # Recursion was not successful and we cannot backtrack for a new max
        # jump height.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.UNABLE_TO_BACKTRACK
        return null
    
    if edge_calc_params.have_backtracked_for_surface(
            collision.surface,
            vertical_step.time_instruction_end):
        # We've already tried backtracking for a collision with this surface,
        # so this movement won't work. Without this check, we'd recurse through
        # a traversal branch that is identical to one we've already considered,
        # and we'd loop infinitely.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.ALREADY_BACKTRACKED_FOR_SURFACE
        return null
    
    edge_calc_params.record_backtracked_surface(
            collision.surface,
            vertical_step.time_instruction_end)
    
    if !edge_calc_params.movement_params \
            .backtracks_for_higher_jumps_during_hor_step_calculations:
        # This character is configured to abandon any backtracking for higher
        # jumps.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.CONFIGURED_TO_SKIP_BACKTRACKING
        return null
    
    # Then, try to satisfy the waypoints with an increased jump height.
    if edge_calc_params.movement_params \
            .reuses_previous_waypoints_when_backtracking_on_jump_height:
        # FIXME: Finish debugging this.
        calc_result = \
                calculate_steps_between_waypoints_with_increasing_jump_height(
                        edge_result_metadata,
                        step_result_metadata,
                        edge_calc_params,
                        step_calc_params,
                        waypoints)
    else:
        calc_result = \
                calculate_steps_between_waypoints_with_backtracking_on_height(
                        edge_result_metadata,
                        step_result_metadata,
                        edge_calc_params,
                        step_calc_params,
                        waypoints)
    
    if calc_result != null:
        # Recursion was successful with backtracking for a new max jump height.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.BACKTRACKING_VALID
    else:
        # Recursion was not successful, despite backtracking for a new max jump
        # height.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.BACKTRACKING_INVALID
    
    return calc_result


# Check whether either waypoint can be satisfied with our current max jump
# height.
static func calculate_steps_between_waypoints_without_backtracking_on_height(
        edge_result_metadata: EdgeCalcResultMetadata,
        step_result_metadata: EdgeStepCalcResultMetadata,
        edge_calc_params: EdgeCalcParams,
        step_calc_params: EdgeStepCalcParams,
        waypoints: Array) -> EdgeCalcResult:
    Sc.profiler.increment_count(
            "calculate_steps_between_waypoints_without_backtracking_on_height",
            edge_calc_params.collision_params.thread_id,
            edge_result_metadata)
    
    var vertical_step := step_calc_params.vertical_step
    var previous_waypoint_original := step_calc_params.start_waypoint
    var next_waypoint_original := step_calc_params.end_waypoint
    var origin_original := edge_calc_params.origin_waypoint
    var destination_original := edge_calc_params.destination_waypoint
    
    var previous_waypoint_copy: Waypoint
    var next_waypoint_copy: Waypoint
    var result: EdgeCalcResult
    
    for waypoint in waypoints:
        if !waypoint.is_valid:
            # This waypoint is out of reach.
            continue
        
        # Make copies of the previous and next waypoints. We don't want to
        # update the originals, unless we know the recursion was successful, in
        # case this recursion fails.
        previous_waypoint_copy = \
                WaypointUtils.clone_waypoint(previous_waypoint_original)
        next_waypoint_copy = \
                WaypointUtils.clone_waypoint(next_waypoint_original)
        waypoint.previous_waypoint = previous_waypoint_copy
        previous_waypoint_copy.next_waypoint = waypoint
        waypoint.next_waypoint = next_waypoint_copy
        next_waypoint_copy.previous_waypoint = waypoint
        if previous_waypoint_original == origin_original:
            edge_calc_params.origin_waypoint = previous_waypoint_copy
        if next_waypoint_original == destination_original:
            edge_calc_params.destination_waypoint = next_waypoint_copy
        
        # Update the previous and next waypoints, to account for this new
        # intermediate waypoint. These updates do not solve all cases, since we
        # may in turn need to update the min/max/actual x-velocities and
        # movement sign for all other waypoints. And these updates could then
        # result in the addition/removal of other intermediate waypoints. But
        # we have found that these two updates are enough for most cases.
        WaypointUtils.update_neighbors_for_new_waypoint(
                waypoint,
                previous_waypoint_copy,
                next_waypoint_copy,
                edge_calc_params,
                vertical_step)
        if !previous_waypoint_copy.is_valid or !next_waypoint_copy.is_valid:
            continue
        
        ### RECURSE: Calculate movement to the waypoint.
        
        var step_calc_params_to_waypoint := EdgeStepCalcParams.new(
                previous_waypoint_copy,
                waypoint,
                vertical_step)
        var child_step_result_metadata: EdgeStepCalcResultMetadata
        if step_result_metadata != null:
            child_step_result_metadata = EdgeStepCalcResultMetadata.new(
                    edge_result_metadata,
                    step_result_metadata,
                    step_calc_params_to_waypoint,
                    null)
        var calc_results_to_waypoint := calculate_steps_between_waypoints(
                edge_result_metadata,
                child_step_result_metadata,
                edge_calc_params,
                step_calc_params_to_waypoint)
        
        if calc_results_to_waypoint == null:
            # This waypoint is out of reach with the current jump height.
            continue
        
        if calc_results_to_waypoint.increased_jump_height:
            # When backtracking occurs, the result includes all steps from
            # origin to destination, so we can just return that result here.
            result = calc_results_to_waypoint
            break
        
        ### RECURSE: Calculate movement from the waypoint to the original
        ###          destination.
        
        var step_calc_params_from_waypoint := EdgeStepCalcParams.new(
                waypoint,
                next_waypoint_copy,
                vertical_step)
        if step_result_metadata != null:
            child_step_result_metadata = EdgeStepCalcResultMetadata.new(
                    edge_result_metadata,
                    step_result_metadata,
                    step_calc_params_from_waypoint,
                    null)
        var calc_results_from_waypoint := calculate_steps_between_waypoints(
                edge_result_metadata,
                child_step_result_metadata,
                edge_calc_params,
                step_calc_params_from_waypoint)
        
        if calc_results_from_waypoint == null:
            # This waypoint is out of reach with the current jump height.
            continue
        
        if calc_results_from_waypoint.increased_jump_height:
            # When backtracking occurs, the result includes all steps from
            # origin to destination, so we can just return that result here.
            result = calc_results_from_waypoint
            break
        
        # We found movement that satisfies the waypoint (without backtracking
        # for a new jump height).
        Sc.utils.concat(
                calc_results_to_waypoint.horizontal_steps,
                calc_results_from_waypoint.horizontal_steps)
        result = calc_results_to_waypoint
        break
    
    if result != null:
        # Update the original waypoints to match the state for this successful
        # navigation.
        WaypointUtils.copy_waypoint(
                previous_waypoint_original,
                previous_waypoint_copy)
        WaypointUtils.copy_waypoint(
                next_waypoint_original,
                next_waypoint_copy)
        previous_waypoint_copy.next_waypoint.previous_waypoint = \
                previous_waypoint_original
        next_waypoint_copy.previous_waypoint.next_waypoint = \
                next_waypoint_original
    edge_calc_params.origin_waypoint = origin_original
    edge_calc_params.destination_waypoint = destination_original
    
    return result


# Considers whether an increased jump height would enable movement through
# either of the given waypoints around a colliding surface. If so, then the
# returned result includes all steps from the origin to the destination.
# 
# - This works by first calculating whether a higher jump could possibly allow
#   movement to go through the new waypoint and then to the destination.
# - If so, this then updates all previous waypoints to use this new jump
#   height.
# - And then this updates all previous horizontal steps to use this new jump
#   height.
static func calculate_steps_between_waypoints_with_increasing_jump_height(
        edge_result_metadata: EdgeCalcResultMetadata,
        step_result_metadata: EdgeStepCalcResultMetadata,
        edge_calc_params: EdgeCalcParams,
        step_calc_params: EdgeStepCalcParams,
        waypoints_around_colliding_surface: Array) -> EdgeCalcResult:
    var vertical_step_original := step_calc_params.vertical_step
    var origin_original := edge_calc_params.origin_waypoint
    var destination_original := edge_calc_params.destination_waypoint
    var previous_waypoint_original := step_calc_params.start_waypoint
    var next_waypoint_original := step_calc_params.end_waypoint
    
    # Create copies of all previously calculated waypoints, so we don't
    # conflict with other recursion branches, in case this branch fails.
    var all_waypoint_copies := []
    var current_waypoint_copy: Waypoint
    var previous_waypoint_copy: Waypoint
    var next_waypoint_copy: Waypoint
    var current_waypoint_original := origin_original
    while current_waypoint_original != null:
        current_waypoint_copy = \
                WaypointUtils.clone_waypoint(current_waypoint_original)
        if current_waypoint_original == next_waypoint_original:
            next_waypoint_copy = current_waypoint_copy
        if previous_waypoint_copy != null:
            current_waypoint_copy.previous_waypoint = previous_waypoint_copy
            previous_waypoint_copy.next_waypoint = current_waypoint_copy
        all_waypoint_copies.push_back(current_waypoint_copy)
        current_waypoint_original = current_waypoint_original.next_waypoint
        previous_waypoint_copy = current_waypoint_copy
    
    var origin_copy: Waypoint = all_waypoint_copies.front()
    var destination_copy: Waypoint = all_waypoint_copies.back()
    assert(next_waypoint_copy != null)
    previous_waypoint_copy = next_waypoint_copy.previous_waypoint
    
    edge_calc_params.origin_waypoint = origin_copy
    edge_calc_params.destination_waypoint = destination_copy
    
    var previous_calc_results: EdgeCalcResult
    
    for waypoint_around_collision in waypoints_around_colliding_surface:
        # Create a copy of the collision waypoint (so we don't conflict with
        # other recursion branches), and update previous/next pointers.
        var waypoint_around_collision_copy := \
                WaypointUtils.clone_waypoint(waypoint_around_collision)
        waypoint_around_collision_copy.previous_waypoint = \
                previous_waypoint_copy
        previous_waypoint_copy.next_waypoint = \
                waypoint_around_collision_copy
        waypoint_around_collision_copy.next_waypoint = destination_copy
        destination_copy.previous_waypoint = waypoint_around_collision_copy
        
        # Update the destination waypoint to support a (possibly) increased
        # jump height, which would enable movement through this new
        # intermediate waypoint.
        WaypointUtils.update_waypoint(
                destination_copy,
                origin_copy,
                edge_calc_params.movement_params,
                vertical_step_original.velocity_step_start,
                true,
                vertical_step_original,
                waypoint_around_collision.position)
        if !destination_copy.is_valid:
            # The waypoint is out of reach.
            continue
        
        var vertical_step_with_increased_height := \
                VerticalMovementUtils.calculate_vertical_step(
                        edge_result_metadata,
                        edge_calc_params)
        if vertical_step_with_increased_height == null:
            # The new jump height is invalid.
            continue
        
        # Update all other previous waypoints to account for the new
        # destination waypoint parameters and the (possibly) increased jump
        # height. Update in reverse order.
        current_waypoint_copy = destination_copy.previous_waypoint
        while current_waypoint_copy != null:
            WaypointUtils.update_waypoint(
                    current_waypoint_copy,
                    origin_copy,
                    edge_calc_params.movement_params,
                    vertical_step_with_increased_height.velocity_step_start,
                    true,
                    vertical_step_with_increased_height,
                    Vector2.INF)
            if !current_waypoint_copy.is_valid:
                # The waypoint is out of reach.
                break
            current_waypoint_copy = current_waypoint_copy.previous_waypoint
        if current_waypoint_copy != null and \
                !current_waypoint_copy.is_valid:
            # The new jump height is invalid.
            continue
        
        # Re-calculate each horizontal step through all previous waypoints
        # (because the increased jump height, the time, min/max/actual
        # x-velocity, and trajectories can all be different). Update in forward
        # order.
        var was_horizontal_step_already_validated := true
        previous_waypoint_copy = origin_copy
        current_waypoint_copy = origin_copy.next_waypoint
        while current_waypoint_copy != null:
            if current_waypoint_copy == waypoint_around_collision_copy:
                # All steps before the current collision waypoint should have
                # already been calculated and determined to be valid.
                was_horizontal_step_already_validated = false
            
            var step_calc_params_between_waypoints := EdgeStepCalcParams.new(
                    previous_waypoint_copy,
                    current_waypoint_copy,
                    vertical_step_with_increased_height)
            
            var step_result_metadata_between_waypoints: \
                    EdgeStepCalcResultMetadata
            if step_result_metadata != null:
                step_result_metadata_between_waypoints = \
                        EdgeStepCalcResultMetadata.new(
                                edge_result_metadata,
                                step_result_metadata,
                                step_calc_params_between_waypoints,
                                waypoint_around_collision_copy)
            
            var current_calc_results := calculate_steps_between_waypoints(
                    edge_result_metadata,
                    step_result_metadata_between_waypoints,
                    edge_calc_params,
                    step_calc_params_between_waypoints)
            
            if current_calc_results == null:
                # This step is not valid with the new jump height.
                previous_calc_results = null
                break
            
            if current_calc_results.increased_jump_height:
                # If a recursive call found a valid step with backtracking,
                # then it also returned all steps for the entire edge.
                previous_calc_results = current_calc_results
                break
            
            if was_horizontal_step_already_validated and \
                    current_calc_results.horizontal_steps.size() != 1:
                # Updating the jump-height invalidates this previously valid
                # step.
                previous_calc_results = null
                break
            
            if previous_calc_results != null:
                # Combine all the horizontal steps.
                Sc.utils.concat(
                        previous_calc_results.horizontal_steps,
                        current_calc_results.horizontal_steps)
            else:
                previous_calc_results = current_calc_results
            
            previous_waypoint_copy = current_waypoint_copy
            current_waypoint_copy = current_waypoint_copy.next_waypoint
        
        if previous_calc_results != null:
            # The new waypoint is within reach, and we were able to find valid
            # movement steps to the destination.
            previous_calc_results.increased_jump_height = true
            break
    
    # Reconcile copy vs original state.
    if previous_calc_results != null:
        # Update the original destination waypoint to match the state for this
        # successful navigation.
        WaypointUtils.copy_waypoint(
                origin_original,
                origin_copy)
        WaypointUtils.copy_waypoint(
                destination_original,
                destination_copy)
        origin_copy.next_waypoint.previous_waypoint = origin_original
        destination_copy.previous_waypoint.next_waypoint = destination_original
    edge_calc_params.origin_waypoint = origin_original
    edge_calc_params.destination_waypoint = destination_original
    
    return previous_calc_results


# Check whether either waypoint can be satisfied if we backtrack to
# re-calculate the initial vertical step with a higher max jump height. This
# function recalculates all intermediate waypoints and horizontal steps, rather
# than re-using anything that was already calculated.
static func calculate_steps_between_waypoints_with_backtracking_on_height(
        edge_result_metadata: EdgeCalcResultMetadata,
        step_result_metadata: EdgeStepCalcResultMetadata,
        edge_calc_params: EdgeCalcParams,
        step_calc_params: EdgeStepCalcParams,
        waypoints: Array) -> EdgeCalcResult:
    Sc.profiler.increment_count(
            "calculate_steps_between_waypoints_with_backtracking_on_height",
            edge_calc_params.collision_params.thread_id,
            edge_result_metadata)
    
    var vertical_step_original := step_calc_params.vertical_step
    var origin_original := edge_calc_params.origin_waypoint
    var destination_original := edge_calc_params.destination_waypoint
    var origin_copy: Waypoint
    var destination_copy: Waypoint
    var calc_result: EdgeCalcResult
    
    for waypoint in waypoints:
        if waypoint.is_valid:
            # This waypoint was already in reach, so we don't need to try
            # increasing jump height for it.
            continue
        
        # Make a copy of the destination waypoint. We don't want to update the
        # original, unless we know the backtracking succeeded.
        origin_copy = WaypointUtils.clone_waypoint(origin_original)
        destination_copy = WaypointUtils.clone_waypoint(destination_original)
        origin_copy.next_waypoint = destination_copy
        destination_copy.previous_waypoint = origin_copy
        edge_calc_params.origin_waypoint = origin_copy
        edge_calc_params.destination_waypoint = destination_copy
        
        # Update the destination waypoint to support a (possibly) increased
        # jump height, which would enable movement through this new
        # intermediate waypoint.
        WaypointUtils.update_waypoint(
                destination_copy,
                edge_calc_params.origin_waypoint,
                edge_calc_params.movement_params,
                vertical_step_original.velocity_step_start,
                true,
                vertical_step_original,
                waypoint.position)
        if !destination_copy.is_valid:
            # The waypoint is out of reach.
            continue
        
        # Recurse: Backtrack and try a higher jump (to the same destination
        # waypoint as before).
        calc_result = calculate_steps_with_new_jump_height(
                edge_result_metadata,
                edge_calc_params,
                step_result_metadata,
                waypoint)
        
        if calc_result != null:
            # The waypoint is within reach, and we were able to find valid
            # movement steps to the destination.
            calc_result.increased_jump_height = true
            break
    
    if calc_result != null:
        # Update the original destination waypoint to match the state for this
        # successful navigation.
        WaypointUtils.copy_waypoint(
                origin_original,
                origin_copy)
        WaypointUtils.copy_waypoint(
                destination_original,
                destination_copy)
        origin_copy.next_waypoint.previous_waypoint = origin_original
        destination_copy.previous_waypoint.next_waypoint = destination_original
    edge_calc_params.origin_waypoint = origin_original
    edge_calc_params.destination_waypoint = destination_original
    
    return calc_result
