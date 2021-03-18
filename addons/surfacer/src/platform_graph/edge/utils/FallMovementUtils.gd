# A collection of utility functions for calculating state related to fall
# movement.
extends Reference
class_name FallMovementUtils

# TODO: Integrate find_landing_trajectories_to_any_surface with
#       failed_edge_attempts_result and
#       find_landing_trajectory_between_positions.

# Finds all possible landing trajectories from the given start state.
static func find_landing_trajectories_to_any_surface( \
        inter_surface_edges_results: Array, \
        collision_params: CollisionCalcParams, \
        all_possible_surfaces_set: Dictionary, \
        origin_position: PositionAlongSurface, \
        velocity_start: Vector2, \
        calculator, \
        records_profile := false, \
        possible_landing_surfaces_from_point := [], \
        only_returns_first_result := false) -> void:
    var debug_params := collision_params.debug_params
    var movement_params := collision_params.movement_params
    
    if possible_landing_surfaces_from_point.empty():
        # Calculate which surfaces are within landing reach.
        Profiler.start( \
                ProfilerMetric.FIND_SURFACES_IN_FALL_RANGE_FROM_POINT, \
                collision_params.thread_id)
        var possible_landing_surfaces_result_set := {}
        find_surfaces_in_fall_range_from_point( \
                movement_params, \
                all_possible_surfaces_set, \
                possible_landing_surfaces_result_set, \
                origin_position.target_point, \
                velocity_start)
        possible_landing_surfaces_from_point = \
                possible_landing_surfaces_result_set.keys()
        Profiler.stop( \
                ProfilerMetric.FIND_SURFACES_IN_FALL_RANGE_FROM_POINT, \
                collision_params.thread_id, \
                records_profile)
    
    var jump_land_positions_to_consider: Array
    var inter_surface_edges_result: InterSurfaceEdgesResult
    var edge_result_metadata: EdgeCalcResultMetadata
    var calc_result: EdgeCalcResult
    var failed_attempt: FailedEdgeAttempt
    var jump_land_position_results_for_destination_surface := []
    
    # Find the first possible edge to a landing surface.
    for destination_surface in possible_landing_surfaces_from_point:
        #######################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if EdgeCalculator.should_skip_edge_calculation( \
                debug_params, \
                origin_position, \
                destination_surface, \
                velocity_start):
            continue
        #######################################################################
        
        if origin_position.surface == destination_surface:
            # We don't need to calculate edges for the degenerate case.
            continue
        
        jump_land_position_results_for_destination_surface.clear()
        
        Profiler.start( \
                ProfilerMetric.CALCULATE_LAND_POSITIONS_ON_SURFACE, \
                collision_params.thread_id)
        jump_land_positions_to_consider = \
                JumpLandPositionsUtils.calculate_land_positions_on_surface( \
                        movement_params, \
                        destination_surface, \
                        origin_position, \
                        velocity_start)
        Profiler.stop( \
                ProfilerMetric.CALCULATE_LAND_POSITIONS_ON_SURFACE, \
                collision_params.thread_id, \
                records_profile)
        
        inter_surface_edges_result = InterSurfaceEdgesResult.new( \
                origin_position.surface, \
                destination_surface, \
                calculator.edge_type, \
                jump_land_positions_to_consider)
        inter_surface_edges_results.push_back(inter_surface_edges_result)
        
        for jump_land_positions in jump_land_positions_to_consider:
            ###################################################################
            # Record some extra debug state when we're limiting calculations to
            # a single edge (which must be this edge).
            var records_calc_details: bool = \
                    debug_params.has("limit_parsing") and \
                    debug_params.limit_parsing.has("edge") and \
                    debug_params.limit_parsing.edge.has("origin") and \
                    debug_params.limit_parsing.edge.origin.has( \
                            "position") and \
                    debug_params.limit_parsing.edge.has("destination") and \
                    debug_params.limit_parsing.edge.destination.has("position")
            ###################################################################
            
            edge_result_metadata = EdgeCalcResultMetadata.new( \
                    records_calc_details, \
                    records_profile)
            
            if !EdgeCalculator.broad_phase_check( \
                    edge_result_metadata, \
                    collision_params, \
                    jump_land_positions, \
                    jump_land_position_results_for_destination_surface, \
                    true):
                failed_attempt = FailedEdgeAttempt.new( \
                        jump_land_positions, \
                        edge_result_metadata, \
                        calculator)
                inter_surface_edges_result.failed_edge_attempts.push_back( \
                        failed_attempt)
                continue
            
            calc_result = find_landing_trajectory_between_positions( \
                    edge_result_metadata, \
                    collision_params, \
                    jump_land_positions.jump_position, \
                    jump_land_positions.land_position, \
                    velocity_start, \
                    jump_land_positions.needs_extra_wall_land_horizontal_speed)
            
            if calc_result != null:
                inter_surface_edges_result.edge_calc_results.push_back( \
                        calc_result)
                calc_result = null
                jump_land_position_results_for_destination_surface.push_back( \
                        jump_land_positions)
                
                if only_returns_first_result:
                    return
            else:
                failed_attempt = FailedEdgeAttempt.new( \
                        jump_land_positions, \
                        edge_result_metadata, \
                        calculator)
                inter_surface_edges_result.failed_edge_attempts.push_back( \
                        failed_attempt)

static func find_landing_trajectory_between_positions( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        collision_params: CollisionCalcParams, \
        origin_position: PositionAlongSurface, \
        land_position: PositionAlongSurface, \
        velocity_start: Vector2, \
        needs_extra_wall_land_horizontal_speed: bool) -> EdgeCalcResult:
    var debug_params := collision_params.debug_params
    
    ###########################################################################
    # Allow for debug mode to limit the scope of what's calculated.
    if EdgeCalculator.should_skip_edge_calculation( \
            debug_params, \
            origin_position, \
            land_position, \
            velocity_start):
        return null
    
    # Record some extra debug state when we're limiting calculations to a
    # single edge (which must be this edge).
    var records_calc_details: bool = \
            (edge_result_metadata != null and \
                    edge_result_metadata.records_calc_details) or \
            (debug_params.has("limit_parsing") and \
            debug_params.limit_parsing.has("edge") and \
            debug_params.limit_parsing.edge.has("origin") and \
            debug_params.limit_parsing.edge.origin.has("position") and \
            debug_params.limit_parsing.edge.has("destination") and \
            debug_params.limit_parsing.edge.destination.has("position"))
    ###########################################################################
        
    edge_result_metadata = \
            edge_result_metadata if \
            edge_result_metadata != null else \
            EdgeCalcResultMetadata.new(records_calc_details, false)
    
    Profiler.start( \
            ProfilerMetric.FIND_LANDING_TRAJECTORY_BETWEEN_POSITIONS, \
            collision_params.thread_id)
    
    var edge_calc_params: EdgeCalcParams = \
            EdgeCalculator.create_edge_calc_params( \
                    edge_result_metadata, \
                    collision_params, \
                    origin_position, \
                    land_position, \
                    false, \
                    velocity_start, \
                    false, \
                    needs_extra_wall_land_horizontal_speed)
    if edge_calc_params == null:
        # Cannot reach destination from origin.
        assert(!EdgeCalcResultType.get_is_valid( \
                edge_result_metadata.edge_calc_result_type))
        Profiler.stop_with_optional_metadata( \
                ProfilerMetric.FIND_LANDING_TRAJECTORY_BETWEEN_POSITIONS, \
                collision_params.thread_id, \
                edge_result_metadata)
        return null
    
    var vertical_step: VerticalEdgeStep = \
            VerticalMovementUtils.calculate_vertical_step( \
                    edge_result_metadata, \
                    edge_calc_params)
    if vertical_step == null:
        # Cannot reach destination from origin.
        assert(!EdgeCalcResultType.get_is_valid( \
                edge_result_metadata.edge_calc_result_type))
        Profiler.stop_with_optional_metadata( \
                ProfilerMetric.FIND_LANDING_TRAJECTORY_BETWEEN_POSITIONS, \
                collision_params.thread_id, \
                edge_result_metadata)
        return null
    
    var step_calc_params: EdgeStepCalcParams = EdgeStepCalcParams.new( \
            edge_calc_params.origin_waypoint, \
            edge_calc_params.destination_waypoint, \
            vertical_step)
    
    var step_result_metadata: EdgeStepCalcResultMetadata
    if edge_result_metadata.records_calc_details:
        step_result_metadata = EdgeStepCalcResultMetadata.new( \
                edge_result_metadata, \
                null, \
                step_calc_params, \
                null)
    
    Profiler.start( \
            ProfilerMetric.NARROW_PHASE_EDGE_CALCULATION, \
            collision_params.thread_id)
    var calc_result := EdgeStepUtils.calculate_steps_between_waypoints( \
            edge_result_metadata, \
            step_result_metadata, \
            edge_calc_params, \
            step_calc_params)
    Profiler.stop_with_optional_metadata( \
            ProfilerMetric.NARROW_PHASE_EDGE_CALCULATION, \
            collision_params.thread_id, \
            edge_result_metadata)
    
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
    
    Profiler.stop_with_optional_metadata( \
            ProfilerMetric.FIND_LANDING_TRAJECTORY_BETWEEN_POSITIONS, \
            collision_params.thread_id, \
            edge_result_metadata)
    
    return calc_result

static func find_surfaces_in_fall_range_from_point( \
        movement_params: MovementParams, \
        all_possible_surfaces_set: Dictionary, \
        result_set: Dictionary, \
        origin: Vector2, \
        velocity_start: Vector2) -> void:
    # FIXME: Offset the start_position_offset to account for velocity_start.
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    # NOTE: This makes the simplifying assumption that the player cannot still
    #       be pressing the jump button, and we only need to consider fast-fall
    #       gravity.
    var time_to_terminal_velocity_y := \
            (movement_params.max_vertical_speed - velocity_start.y) / \
            movement_params.gravity_fast_fall
    
    # This offset should account for the extra horizontal range before the
    # player has reached terminal velocity.
    # From a basic equation of motion:
    #     s = s_0 + v*t
    var offset_x_for_acceleration_to_terminal_velocity := \
            movement_params.max_horizontal_speed_default * \
            time_to_terminal_velocity_y
    
    var offset_for_acceleration_to_terminal_velocity := \
            Vector2(offset_x_for_acceleration_to_terminal_velocity, 0.0)
    var slope := movement_params.max_vertical_speed / \
            movement_params.max_horizontal_speed_default
    var offset_x_from_top_corner_to_bottom_corner := 10000.0
    var offset_y_from_top_corner_to_bottom_corner := 10000.0 * slope
    
    var top_left := origin - offset_for_acceleration_to_terminal_velocity
    var top_right := origin + offset_for_acceleration_to_terminal_velocity
    var bottom_left := top_left + Vector2( \
            -offset_x_from_top_corner_to_bottom_corner, \
            offset_y_from_top_corner_to_bottom_corner)
    var bottom_right := top_right + Vector2( \
            offset_x_from_top_corner_to_bottom_corner, \
            offset_y_from_top_corner_to_bottom_corner)
    
    _get_surfaces_intersecting_polygon( \
            result_set, \
            [top_left, top_right, bottom_right, bottom_left, top_left], \
            all_possible_surfaces_set)

static func find_surfaces_in_fall_range_from_surface( \
        movement_params: MovementParams, \
        all_possible_surfaces_set: Dictionary, \
        surfaces_in_fall_range_without_jump_distance_result_set: Dictionary, \
        surfaces_in_fall_range_with_jump_distance_result_set: Dictionary, \
        origin_surface: Surface) -> void:
    # Only expand calculate the jump-distance results, if the corresponding
    # result set is given.
    var is_considering_jump_distance := \
            surfaces_in_fall_range_with_jump_distance_result_set != null
    
    var fall_range_polygon_with_jump_distance := \
            calculate_jump_or_fall_range_polygon_from_surface( \
                    movement_params, \
                    origin_surface, \
                    true) if \
            is_considering_jump_distance else \
            []
    
    var fall_range_polygon_without_jump_distance := \
            calculate_jump_or_fall_range_polygon_from_surface( \
                    movement_params, \
                    origin_surface, \
                    false)
    
    if is_considering_jump_distance:
        _get_surfaces_intersecting_polygon( \
                surfaces_in_fall_range_with_jump_distance_result_set, \
                fall_range_polygon_with_jump_distance, \
                all_possible_surfaces_set)
        
        # Limit the possible surfaces for the following
        # without-jump-distance calculation to be a subset of the
        # with-jump-distance result.
        all_possible_surfaces_set = \
                surfaces_in_fall_range_with_jump_distance_result_set
    
    _get_surfaces_intersecting_polygon( \
            surfaces_in_fall_range_without_jump_distance_result_set, \
            fall_range_polygon_without_jump_distance, \
            all_possible_surfaces_set)

static func calculate_jump_or_fall_range_polygon_from_surface( \
        movement_params: MovementParams, \
        origin_surface: Surface, \
        is_considering_jump_distance: bool) -> Array:
    # FIXME: Offset the start_position_offset to account for velocity_start.
    # FIXME: There may be cases when it's worth considering both
    #        offset_for_acceleration_to_terminal_velocity and
    #        offset_for_jump_distance together.
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    #     v_0 = 0.0
    # NOTE: This makes the simplifying assumption that the player cannot still
    #       be pressing the jump button, and we only need to consider fast-fall
    #       gravity.
    var time_to_terminal_velocity_y := \
            movement_params.max_vertical_speed / \
            movement_params.gravity_fast_fall
    
    # This offset should account for the extra horizontal range before the
    # player has reached terminal velocity.
    # From a basic equation of motion:
    #     s = s_0 + v*t
    var offset_x_for_acceleration_to_terminal_velocity := \
            movement_params.max_horizontal_speed_default * \
            time_to_terminal_velocity_y
    
    var offset_for_acceleration_to_terminal_velocity := \
            Vector2(offset_x_for_acceleration_to_terminal_velocity, 0.0)
    var slope := movement_params.max_vertical_speed / \
            movement_params.max_horizontal_speed_default
    var offset_x_from_top_corner_to_bottom_corner := 100000.0
    var offset_y_from_top_corner_to_bottom_corner := 100000.0 * slope
    
    # FIXME: Make this more specifically consider the distance in left/right
    #        directions separately, depending on which wall wall side we're
    #        jumping from.
    
    var max_horizontal_jump_distance := \
            movement_params.get_max_horizontal_jump_distance( \
                    origin_surface.side) if \
            is_considering_jump_distance else \
            0.0
    var horizontal_offset_during_jump_vertical_offset := \
            movement_params.max_upward_jump_distance / slope
    var offset_x_to_top_corner := \
            max_horizontal_jump_distance - \
            horizontal_offset_during_jump_vertical_offset
    var offset_y_to_top_corner := -movement_params.max_upward_jump_distance
    
    var top_left := Vector2.INF
    var top_right := Vector2.INF
    var bottom_left := Vector2.INF
    var bottom_right := Vector2.INF
    
    match origin_surface.side:
        SurfaceSide.LEFT_WALL:
            if is_considering_jump_distance:
                top_left = origin_surface.first_point + Vector2( \
                        -offset_x_to_top_corner, \
                        offset_y_to_top_corner)
                top_right = origin_surface.first_point + Vector2( \
                        offset_x_to_top_corner, \
                        offset_y_to_top_corner)
                bottom_left = top_left + Vector2( \
                        -offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2( \
                        offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
            else:
                # For falling from a left-side wall, we can only fall leftward
                # from bottom point, and we can fall the furthest rightward
                # from the top point. So we call the bottom point the
                # "top-left" and we call the top point the "top-right".
                top_left = origin_surface.last_point - \
                        offset_for_acceleration_to_terminal_velocity
                top_right = origin_surface.first_point + \
                        offset_for_acceleration_to_terminal_velocity
                bottom_left = top_left + Vector2( \
                        -offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2( \
                        offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
            
        SurfaceSide.RIGHT_WALL:
            if is_considering_jump_distance:
                top_left = \
                        origin_surface.last_point + Vector2( \
                        -offset_x_to_top_corner, \
                        offset_y_to_top_corner)
                top_right = \
                        origin_surface.last_point + Vector2( \
                        offset_x_to_top_corner, \
                        offset_y_to_top_corner)
                bottom_left = top_left + Vector2( \
                        -offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2( \
                        offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
            else:
                # For falling from a right-side wall, we can only fall
                # rightward from bottom point, and we can fall the furthest
                # leftward from the top point. So we call the top point the
                # "top-left" and we call the bottom point the "top-right".
                top_left = origin_surface.last_point - \
                        offset_for_acceleration_to_terminal_velocity
                top_right = origin_surface.first_point + \
                        offset_for_acceleration_to_terminal_velocity
                bottom_left = top_left + Vector2( \
                        -offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2( \
                        offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
            
        SurfaceSide.FLOOR:
            if is_considering_jump_distance:
                top_left = \
                        origin_surface.first_point + Vector2( \
                        -offset_x_to_top_corner, \
                        offset_y_to_top_corner)
                top_right = \
                        origin_surface.last_point + Vector2( \
                        offset_x_to_top_corner, \
                        offset_y_to_top_corner)
                bottom_left = top_left + Vector2( \
                        -offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2( \
                        offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
            else:
                top_left = origin_surface.first_point - \
                        offset_for_acceleration_to_terminal_velocity
                top_right = origin_surface.last_point + \
                        offset_for_acceleration_to_terminal_velocity
                bottom_left = top_left + Vector2( \
                        -offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2( \
                        offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
            
        _:
            ScaffoldUtils.error()
            return []
    
    return [top_left, top_right, bottom_right, bottom_left, top_left]

# This is only an approximation, since it only considers the end points of the
# surface rather than each segment of the surface polyline.
static func _get_surfaces_intersecting_triangle( \
        triangle_a: Vector2, \
        triangle_b: Vector2, \
        triangle_c: Vector2, \
        surfaces: Array) -> Array:
    var result := []
    for surface in surfaces:
        if Geometry.do_segment_and_triangle_intersect( \
                surface.vertices.front(), \
                surface.vertices.back(), \
                triangle_a, \
                triangle_b, \
                triangle_c):
            result.push_back(surface)
    return result

# This is only an approximation, since it only considers the end points of the
# surface rather than each segment of the surface polyline.
static func _get_surfaces_intersecting_polygon( \
        result_set: Dictionary, \
        polygon: Array, \
        surfaces_set: Dictionary) -> void:
    for surface in surfaces_set:
        if Geometry.do_segment_and_polygon_intersect( \
                surface.first_point, \
                surface.last_point, \
                polygon):
            result_set[surface] = surface
