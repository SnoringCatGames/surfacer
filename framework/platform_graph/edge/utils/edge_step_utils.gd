# A collection of utility functions for calculating state related to
# MovementCalcSteps.
extends Reference
class_name EdgeStepUtils

# Calculates movement steps to reach the given destination.
# 
# This first calculates the one vertical step of the overall movement, using
# the minimum possible peak jump height. It then calculates the horizontal
# steps.
# 
# This can trigger recursive calls if horizontal movement cannot be satisfied
# without backtracking to consider a new higher jump height.
static func calculate_steps_with_new_jump_height( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        edge_calc_params: EdgeCalcParams, \
        parent_step_result_metadata = null, \
        previous_out_of_reach_waypoint = null) -> EdgeCalcResult:
    var vertical_step := VerticalMovementUtils.calculate_vertical_step( \
            edge_result_metadata, \
            edge_calc_params)
    if vertical_step == null:
        # The destination is out of reach.
        return null
    
    var step_calc_params := EdgeStepCalcParams.new( \
            edge_calc_params.origin_waypoint, \
            edge_calc_params.destination_waypoint, \
            vertical_step)
    
    var step_result_metadata: EdgeStepCalcResultMetadata
    if edge_result_metadata.records_calc_details:
        step_result_metadata = EdgeStepCalcResultMetadata.new( \
                edge_result_metadata, \
                parent_step_result_metadata, \
                step_calc_params, \
                previous_out_of_reach_waypoint)
    
    var calc_result := calculate_steps_between_waypoints( \
            edge_result_metadata, \
            step_result_metadata, \
            edge_calc_params, \
            step_calc_params)
    
    edge_result_metadata.edge_calc_result_type = \
            EdgeCalcResultType.FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS if \
            calc_result == null else \
            EdgeCalcResultType.EDGE_VALID
    
    return calc_result

# Recursively calculates a list of movement steps to reach the given
# destination.
# 
# Normally, this function deals with horizontal movement steps. However, if we
# find that a waypoint cannot be satisfied with just horizontal movement, we
# may backtrack and try a new recursive traversal using a higher jump height.
static func calculate_steps_between_waypoints( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        step_result_metadata: EdgeStepCalcResultMetadata, \
        edge_calc_params: EdgeCalcParams, \
        step_calc_params: EdgeStepCalcParams) -> EdgeCalcResult:
    ### BASE CASES
    
    var next_horizontal_step := \
            HorizontalMovementUtils.calculate_horizontal_step( \
                    edge_result_metadata, \
                    step_calc_params, \
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
        assert(Geometry.are_floats_equal_with_epsilon( \
                next_horizontal_step.time_step_end, \
                vertical_step.time_step_end, \
                0.0001))
        assert(Geometry.are_floats_equal_with_epsilon( \
                next_horizontal_step.position_step_end.y, \
                vertical_step.position_step_end.y, \
                0.001))
        assert(Geometry.are_points_equal_with_epsilon( \
                next_horizontal_step.position_step_end, \
                edge_calc_params.destination_waypoint.position, \
                0.0001))
    
    # FIXME: DEBUGGING: REMOVE:
#    if step_calc_params.start_waypoint.position == Vector2(106, 37.5):
#        print("break")

    var collision := CollisionCheckUtils \
            .check_continuous_horizontal_step_for_collision( \
                    step_result_metadata, \
                    edge_calc_params, \
                    step_calc_params, \
                    next_horizontal_step)
    
    if collision != null and \
            !collision.is_valid_collision_state:
        # An error occured during collision detection, so we abandon this step
        # calculation.
        Profiler.increment_count( \
                ProfilerMetric \
                        .INVALID_COLLISION_STATE_IN_CALCULATE_STEPS_BETWEEN_WAYPOINTS, \
                edge_calc_params.collision_params.thread_id, \
                edge_result_metadata)
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.INVALID_COLLISON_STATE
        return null
    
    if collision == null or \
            (collision.surface == \
            edge_calc_params.destination_waypoint.surface):
        # There is no intermediate surface interfering with this movement.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.MOVEMENT_VALID
        return EdgeCalcResult.new( \
                [next_horizontal_step], \
                vertical_step, \
                edge_calc_params)
    
    Profiler.increment_count( \
            ProfilerMetric \
                    .COLLISION_IN_CALCULATE_STEPS_BETWEEN_WAYPOINTS, \
            edge_calc_params.collision_params.thread_id, \
            edge_result_metadata)
    
    ### RECURSIVE CASES
    
    if !edge_calc_params.movement_params \
            .recurses_when_colliding_during_horizontal_step_calculations:
        # This player is configured to abandon any step recursion for
        # intermediate collisions.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.CONFIGURED_TO_SKIP_RECURSION
        return null
    
    # Calculate possible waypoints to divert the movement around either side of
    # the colliding surface.
    var waypoints := WaypointUtils.calculate_waypoints_around_surface( \
            edge_result_metadata, \
            edge_calc_params.collision_params, \
            edge_calc_params.movement_params, \
            vertical_step, \
            step_calc_params.start_waypoint, \
            step_calc_params.end_waypoint, \
            edge_calc_params.origin_waypoint, \
            edge_calc_params.destination_waypoint, \
            collision.surface, \
            edge_calc_params.waypoint_offset)
    if step_result_metadata != null:
        step_result_metadata.upcoming_waypoints = waypoints
    
    # First, try to satisfy the waypoints without backtracking to consider a
    # new max jump height.
    var calc_result := \
            calculate_steps_between_waypoints_without_backtracking_on_height( \
                    edge_result_metadata, \
                    step_result_metadata, \
                    edge_calc_params, \
                    step_calc_params, \
                    waypoints)
    if calc_result != null or !edge_calc_params.can_backtrack_on_height:
        # Recursion was successful without backtracking for a new max jump
        # height.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.RECURSION_VALID
        return calc_result
    
    if edge_calc_params.have_backtracked_for_surface( \
            collision.surface, \
            vertical_step.time_instruction_end):
        # We've already tried backtracking for a collision with this surface,
        # so this movement won't work. Without this check, we'd recurse through
        # a traversal branch that is identical to one we've already considered,
        # and we'd loop infinitely.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.ALREADY_BACKTRACKED_FOR_SURFACE
        return null
    
    edge_calc_params.record_backtracked_surface( \
            collision.surface, \
            vertical_step.time_instruction_end)
    
    if !edge_calc_params.movement_params \
            .backtracks_to_consider_higher_jumps_during_horizontal_step_calculations:
        # This player is configured to abandon any backtracking for higher
        # jumps.
        if step_result_metadata != null:
            step_result_metadata.edge_step_calc_result_type = \
                    EdgeStepCalcResultType.CONFIGURED_TO_SKIP_BACKTRACKING
        return null
    
    # Then, try to satisfy the waypoints with backtracking to consider a new
    # max jump height.
    calc_result = \
            calculate_steps_between_waypoints_with_backtracking_on_height( \
                    edge_result_metadata, \
                    edge_calc_params, \
                    step_calc_params, \
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
static func calculate_steps_between_waypoints_without_backtracking_on_height( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        step_result_metadata: EdgeStepCalcResultMetadata, \
        edge_calc_params: EdgeCalcParams, \
        step_calc_params: EdgeStepCalcParams, \
        waypoints: Array) -> EdgeCalcResult:
    Profiler.increment_count( \
            ProfilerMetric \
                    .CALCULATE_STEPS_BETWEEN_WAYPOINTS_WITHOUT_BACKTRACKING_ON_HEIGHT, \
            edge_calc_params.collision_params.thread_id, \
            edge_result_metadata)
    
    var vertical_step := step_calc_params.vertical_step
    var previous_waypoint_original := step_calc_params.start_waypoint
    var next_waypoint_original := step_calc_params.end_waypoint
    
    var previous_waypoint_copy: Waypoint
    var next_waypoint_copy: Waypoint
    var step_calc_params_to_waypoint: EdgeStepCalcParams
    var step_calc_params_from_waypoint: EdgeStepCalcParams
    var child_step_result_metadata: EdgeStepCalcResultMetadata
    var calc_results_to_waypoint: EdgeCalcResult
    var calc_results_from_waypoint: EdgeCalcResult
    
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
        next_waypoint_copy = WaypointUtils.clone_waypoint(next_waypoint_original)
        
        # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE:
#        if Geometry.are_points_equal_with_epsilon( \
#                waypoint.position, \
#                Vector2(64, -480), 10):
#            print("break")
        
        # FIXME: B: Verify this statement.
        
        # Update the previous and next waypoints, to account for this new
        # intermediate waypoint. These updates do not solve all cases, since we
        # may in turn need to update the min/max/actual x-velocities and
        # movement sign for all other waypoints. And these updates could then
        # result in the addition/removal of other intermediate waypoints. But
        # we have found that these two updates are enough for most cases.
        WaypointUtils.update_neighbors_for_new_waypoint( \
                waypoint, \
                previous_waypoint_copy, \
                next_waypoint_copy, \
                edge_calc_params, \
                vertical_step)
        if !previous_waypoint_copy.is_valid or !next_waypoint_copy.is_valid:
            continue
        
        ### RECURSE: Calculate movement to the waypoint.
        
        step_calc_params_to_waypoint = EdgeStepCalcParams.new( \
                previous_waypoint_copy, \
                waypoint, \
                vertical_step)
        if step_result_metadata != null:
            child_step_result_metadata = EdgeStepCalcResultMetadata.new( \
                    edge_result_metadata, \
                    step_result_metadata, \
                    step_calc_params_to_waypoint, \
                    null)
        calc_results_to_waypoint = calculate_steps_between_waypoints( \
                edge_result_metadata, \
                child_step_result_metadata, \
                edge_calc_params, \
                step_calc_params_to_waypoint)
        
        if calc_results_to_waypoint == null:
            # This waypoint is out of reach with the current jump height.
            continue
        
        if calc_results_to_waypoint.backtracked_for_new_jump_height:
            # When backtracking occurs, the result includes all steps from
            # origin to destination, so we can just return that result here.
            result = calc_results_to_waypoint
            break
        
        ### RECURSE: Calculate movement from the waypoint to the original
        ###          destination.
        
        step_calc_params_from_waypoint = EdgeStepCalcParams.new( \
                waypoint, \
                next_waypoint_copy, \
                vertical_step)
        if step_result_metadata != null:
            child_step_result_metadata = EdgeStepCalcResultMetadata.new( \
                    edge_result_metadata, \
                    step_result_metadata, \
                    step_calc_params_from_waypoint, \
                    null)
        calc_results_from_waypoint = calculate_steps_between_waypoints( \
                edge_result_metadata, \
                child_step_result_metadata, \
                edge_calc_params, \
                step_calc_params_from_waypoint)
        
        if calc_results_from_waypoint == null:
            # This waypoint is out of reach with the current jump height.
            continue
        
        if calc_results_from_waypoint.backtracked_for_new_jump_height:
            # When backtracking occurs, the result includes all steps from
            # origin to destination, so we can just return that result here.
            result = calc_results_from_waypoint
            break
        
        # We found movement that satisfies the waypoint (without backtracking
        # for a new jump height).
        Utils.concat( \
                calc_results_to_waypoint.horizontal_steps, \
                calc_results_from_waypoint.horizontal_steps)
        result = calc_results_to_waypoint
        break
    
    if result != null:
        # Update the original waypoints to match the state for this successful
        # navigation.
        WaypointUtils.copy_waypoint( \
                previous_waypoint_original, \
                previous_waypoint_copy)
        WaypointUtils.copy_waypoint( \
                next_waypoint_original, \
                next_waypoint_copy)
    return result

# Check whether either waypoint can be satisfied if we backtrack to
# re-calculate the initial vertical step with a higher max jump height.
static func calculate_steps_between_waypoints_with_backtracking_on_height( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        edge_calc_params: EdgeCalcParams, \
        step_calc_params: EdgeStepCalcParams, \
        waypoints: Array) -> EdgeCalcResult:
    Profiler.increment_count( \
            ProfilerMetric \
                    .CALCULATE_STEPS_BETWEEN_WAYPOINTS_WITH_BACKTRACKING_ON_HEIGHT, \
            edge_calc_params.collision_params.thread_id, \
            edge_result_metadata)
    
    var origin_original := edge_calc_params.origin_waypoint
    var destination_original := edge_calc_params.destination_waypoint
    var origin_copy: Waypoint
    var destination_copy: Waypoint
    var calc_result: EdgeCalcResult
    
    var result: EdgeCalcResult
    
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
        
        # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE:
#        if step_calc_params.step_result_metadata != null and \
#                step_calc_params.step_result_metadata.index == 5:
#            print("break")
        
        # Update the destination waypoint to support a (possibly) increased
        # jump height, which would enable movement through this new
        # intermediate waypoint.
        WaypointUtils.update_waypoint( \
                destination_copy, \
                edge_calc_params.origin_waypoint, \
                edge_calc_params.movement_params, \
                step_calc_params.vertical_step.velocity_step_start, \
                true, \
                step_calc_params.vertical_step, \
                waypoint.position)
        if !destination_copy.is_valid:
            # The waypoint is out of reach.
            continue
        
        # Recurse: Backtrack and try a higher jump (to the same destination
        # waypoint as before).
        calc_result = calculate_steps_with_new_jump_height( \
                edge_result_metadata, \
                edge_calc_params, \
                step_calc_params, \
                waypoint)
        
        if calc_result != null:
            # The waypoint is within reach, and we were able to find valid
            # movement steps to the destination.
            calc_result.backtracked_for_new_jump_height = true
            result = calc_result
            break
    
    if result != null:
        # Update the original destination waypoint to match the state for this
        # successful navigation.
        WaypointUtils.copy_waypoint( \
                origin_original, \
                origin_copy)
        WaypointUtils.copy_waypoint( \
                destination_original, \
                destination_copy)
        origin_copy.next_waypoint.previous_waypoint = origin_original
        destination_copy.previous_waypoint.next_waypoint = destination_original
    edge_calc_params.origin_waypoint = origin_original
    edge_calc_params.destination_waypoint = destination_original
    
    return result
