# A collection of utility functions for calculating state related to fall movement.
extends Reference
class_name FallMovementUtils

# TODO: Integrate find_landing_trajectories_to_any_surface with failed_edge_attempts_result and
#       find_landing_trajectory_between_positions.

# Finds all possible landing trajectories from the given start state.
static func find_landing_trajectories_to_any_surface( \
        collision_params: CollisionCalcParams, \
        all_possible_surfaces_set: Dictionary, \
        origin_position: PositionAlongSurface, \
        velocity_start: Vector2, \
        possible_landing_surfaces_from_point := [], \
        only_returns_first_result := false) -> Array:
    var debug_params := collision_params.debug_params
    var movement_params := collision_params.movement_params
    
    if possible_landing_surfaces_from_point.empty():
        # Calculate which surfaces are within landing reach.
        var possible_landing_surfaces_result_set := {}
        find_surfaces_in_fall_range_from_point( \
                movement_params, \
                all_possible_surfaces_set, \
                possible_landing_surfaces_result_set, \
                origin_position.target_point, \
                velocity_start)
        possible_landing_surfaces_from_point = possible_landing_surfaces_result_set.keys()
    
    var origin_vertices: Array
    var origin_bounding_box: Rect2
    var origin_side: int
    
    if origin_position.surface != null:
        origin_vertices = origin_position.surface.vertices
        origin_bounding_box = origin_position.surface.bounding_box
        origin_side = origin_position.surface.side
    else:
        origin_vertices = [origin_position.target_point]
        origin_bounding_box = Rect2( \
                origin_position.target_point.x, \
                origin_position.target_point.y, \
                0.0, \
                0.0)
        origin_side = SurfaceSide.CEILING
    
    var jump_land_positions_to_consider: Array
    var calc_result: EdgeCalcResult
    var jump_land_position_results_for_destination_surface := []
    var all_results := []
    
    # Find the first possible edge to a landing surface.
    for destination_surface in possible_landing_surfaces_from_point:
        ###########################################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if EdgeCalculator.should_skip_edge_calculation( \
                debug_params, \
                origin_position, \
                destination_surface):
            continue
        ###########################################################################################
        
        if origin_position.surface == destination_surface:
            # We don't need to calculate edges for the degenerate case.
            continue
        
        jump_land_position_results_for_destination_surface.clear()
        
        jump_land_positions_to_consider = \
                JumpLandPositionsUtils.calculate_land_positions_on_surface( \
                        movement_params, \
                        destination_surface, \
                        origin_position, \
                        velocity_start)
        
        for jump_land_positions in jump_land_positions_to_consider:
            #######################################################################################
            # Allow for debug mode to limit the scope of what's calculated.
            if EdgeCalculator.should_skip_edge_calculation( \
                    debug_params, \
                    jump_land_positions.jump_position, \
                    jump_land_positions.land_position):
                continue
            #######################################################################################
            
            if jump_land_positions.less_likely_to_be_valid and \
                    movement_params.skips_less_likely_jump_land_positions:
                continue
            
            if !jump_land_positions.is_far_enough_from_others( \
                    movement_params, \
                    jump_land_position_results_for_destination_surface, \
                    false, \
                    true):
                # We've already found a valid edge with a land position that's close enough to this
                # land position.
                continue
            
            calc_result = find_landing_trajectory_between_positions( \
                    null, \
                    collision_params, \
                    jump_land_positions.jump_position, \
                    jump_land_positions.land_position, \
                    velocity_start, \
                    jump_land_positions.needs_extra_wall_land_horizontal_speed)
            
            if calc_result != null:
                all_results.push_back(calc_result)
                calc_result = null
                jump_land_position_results_for_destination_surface.push_back(jump_land_positions)
                
                if only_returns_first_result:
                    return all_results
    
    return all_results

static func find_landing_trajectory_between_positions( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        collision_params: CollisionCalcParams, \
        origin_position: PositionAlongSurface, \
        land_position: PositionAlongSurface, \
        velocity_start: Vector2, \
        needs_extra_wall_land_horizontal_speed: bool) -> EdgeCalcResult:
    var debug_params := collision_params.debug_params
    
    ###################################################################################
    # Allow for debug mode to limit the scope of what's calculated.
    if EdgeCalculator.should_skip_edge_calculation( \
            debug_params, \
            origin_position, \
            land_position):
        return null
    
    # Record some extra debug state when we're limiting calculations to a single edge (which must
    # be this edge).
    var record_calc_details: bool = \
            (edge_result_metadata != null and \
                    edge_result_metadata.record_calc_details) or \
            (debug_params.has("limit_parsing") and \
            debug_params.limit_parsing.has("edge") and \
            debug_params.limit_parsing.edge.has("origin") and \
            debug_params.limit_parsing.edge.origin.has("position") and \
            debug_params.limit_parsing.edge.has("destination") and \
            debug_params.limit_parsing.edge.destination.has("position"))
    ###################################################################################
        
    edge_result_metadata = \
            edge_result_metadata if \
            edge_result_metadata != null else \
            EdgeCalcResultMetadata.new(record_calc_details)
        
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
        return null
    
    var vertical_step: VerticalEdgeStep = VerticalMovementUtils.calculate_vertical_step( \
            edge_result_metadata, \
            edge_calc_params)
    if vertical_step == null:
        # Cannot reach destination from origin.
        return null
    
    var step_calc_params: EdgeStepCalcParams = EdgeStepCalcParams.new( \
            edge_calc_params.origin_waypoint, \
            edge_calc_params.destination_waypoint, \
            vertical_step)
    
    var step_result_metadata: EdgeStepCalcResultMetadata
    if edge_result_metadata.record_calc_details:
        step_result_metadata = EdgeStepCalcResultMetadata.new( \
                edge_result_metadata, \
                null, \
                step_calc_params, \
                null)
    
    var calc_result := MovementStepUtils.calculate_steps_between_waypoints( \
            edge_result_metadata, \
            step_result_metadata, \
            edge_calc_params, \
            step_calc_params)
    
    edge_result_metadata.edge_calc_result_type = \
            EdgeCalcResultType.FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS if \
            calc_result == null else \
            EdgeCalcResultType.EDGE_VALID
    
    return calc_result

static func find_surfaces_in_fall_range_from_point( \
        movement_params: MovementParams, \
        all_possible_surfaces_set: Dictionary, \
        result_set: Dictionary, \
        origin: Vector2, \
        velocity_start: Vector2) -> void:
    # FIXME: E: Offset the start_position_offset to account for velocity_start.
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    # NOTE: This makes the simplifying assumption that the player cannot still be pressing the jump
    #       button, and we only need to consider fast-fall gravity.
    var time_to_terminal_velocity_y := (movement_params.max_vertical_speed - velocity_start.y) / \
            movement_params.gravity_fast_fall
    
    # This offset should account for the extra horizontal range before the player has reached
    # terminal velocity.
    # From a basic equation of motion:
    #     s = s_0 + v*t
    var offset_x_for_acceleration_to_terminal_velocity := \
            movement_params.max_horizontal_speed_default * time_to_terminal_velocity_y
    
    var offset_for_acceleration_to_terminal_velocity := \
            Vector2(offset_x_for_acceleration_to_terminal_velocity, 0.0)
    var slope := movement_params.max_vertical_speed / movement_params.max_horizontal_speed_default
    var offset_x_from_top_corner_to_bottom_corner := 10000.0
    var offset_y_from_top_corner_to_bottom_corner := 10000.0 * slope
    
    var top_left := origin - offset_for_acceleration_to_terminal_velocity
    var top_right := origin + offset_for_acceleration_to_terminal_velocity
    var bottom_left := top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
            offset_y_from_top_corner_to_bottom_corner)
    var bottom_right := top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
            offset_y_from_top_corner_to_bottom_corner)
    
    _get_surfaces_intersecting_polygon( \
            result_set, \
            [top_left, top_right, bottom_right, bottom_left], \
            all_possible_surfaces_set)

static func find_surfaces_in_fall_range_from_surface( \
        movement_params: MovementParams, \
        all_possible_surfaces_set: Dictionary, \
        surfaces_in_fall_range_without_jump_distance_result_set: Dictionary, \
        surfaces_in_fall_range_with_jump_distance_result_set: Dictionary, \
        origin_surface: Surface) -> void:
    # FIXME: E: Offset the start_position_offset to account for velocity_start.
    # FIXME: E: There may be cases when it's worth considering both
    #           offset_for_acceleration_to_terminal_velocity and offset_for_jump_distance together.
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    #     v_0 = 0.0
    # NOTE: This makes the simplifying assumption that the player cannot still be pressing the jump
    #       button, and we only need to consider fast-fall gravity.
    var time_to_terminal_velocity_y := \
            movement_params.max_vertical_speed / movement_params.gravity_fast_fall
    
    # This offset should account for the extra horizontal range before the player has reached
    # terminal velocity.
    # From a basic equation of motion:
    #     s = s_0 + v*t
    var offset_x_for_acceleration_to_terminal_velocity := \
            movement_params.max_horizontal_speed_default * time_to_terminal_velocity_y
    
    var offset_for_acceleration_to_terminal_velocity := \
            Vector2(offset_x_for_acceleration_to_terminal_velocity, 0.0)
    var slope := movement_params.max_vertical_speed / movement_params.max_horizontal_speed_default
    var offset_x_from_top_corner_to_bottom_corner := 100000.0
    var offset_y_from_top_corner_to_bottom_corner := 100000.0 * slope
    
    # FIXME: LEFT OFF HERE: ----------------------------------A
    # - Decide whether to adapt this function or create another for the find_a_landing_trajectory
    #   case, where we only start with a single point, rather than a surface.
    
    # Only expand the intersection polygon to consider the jump distance, if the
    # corresponding result set is given.
    var max_horizontal_jump_distance := \
            movement_params.get_max_horizontal_jump_distance(origin_surface.side) if \
            surfaces_in_fall_range_with_jump_distance_result_set != null else \
            0.0
    var offset_for_jump_distance := Vector2(max_horizontal_jump_distance, 0.0)
    
    var top_left := Vector2.INF
    var top_right := Vector2.INF
    var bottom_left := Vector2.INF
    var bottom_right := Vector2.INF
    
    match origin_surface.side:
        SurfaceSide.LEFT_WALL:
            # Only expand calculate the jump-distance results, if the corresponding result set is
            # given.
            if surfaces_in_fall_range_with_jump_distance_result_set != null:
                top_left = origin_surface.first_point - offset_for_jump_distance
                top_right = origin_surface.first_point + offset_for_jump_distance
                bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                _get_surfaces_intersecting_polygon( \
                        surfaces_in_fall_range_with_jump_distance_result_set, \
                        [top_left, top_right, bottom_right, bottom_left], \
                        all_possible_surfaces_set)
                
                # Limit the possible surfaces for the following without-jump-distance calculation
                # to be a subset of the with-jump-distance result.
                all_possible_surfaces_set = surfaces_in_fall_range_with_jump_distance_result_set
            
            # For falling from a left-side wall, we can only fall leftward from bottom point, and
            # we can fall the furthest rightward from the top point. So we call the bottom point
            # the "top-left" and we call the top point the "top-right".
            top_left = origin_surface.last_point - \
                    offset_for_acceleration_to_terminal_velocity
            top_right = origin_surface.first_point + \
                    offset_for_acceleration_to_terminal_velocity
            bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            _get_surfaces_intersecting_polygon( \
                    surfaces_in_fall_range_without_jump_distance_result_set, \
                    [top_left, top_right, bottom_right, bottom_left], \
                    all_possible_surfaces_set)
            
        SurfaceSide.RIGHT_WALL:
            # Only expand calculate the jump-distance results, if the corresponding result set is
            # given.
            if surfaces_in_fall_range_with_jump_distance_result_set != null:
                top_left = origin_surface.last_point - offset_for_jump_distance
                top_right = origin_surface.last_point + offset_for_jump_distance
                bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                _get_surfaces_intersecting_polygon( \
                        surfaces_in_fall_range_with_jump_distance_result_set, \
                        [top_left, top_right, bottom_right, bottom_left], \
                        all_possible_surfaces_set)
                
                # Limit the possible surfaces for the following without-jump-distance calculation
                # to be a subset of the with-jump-distance result.
                all_possible_surfaces_set = surfaces_in_fall_range_with_jump_distance_result_set
            
            # For falling from a right-side wall, we can only fall rightward from bottom point, and
            # we can fall the furthest leftward from the top point. So we call the top point
            # the "top-left" and we call the bottom point the "top-right".
            top_left = origin_surface.last_point - \
                    offset_for_acceleration_to_terminal_velocity
            top_right = origin_surface.first_point + \
                    offset_for_acceleration_to_terminal_velocity
            bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            _get_surfaces_intersecting_polygon( \
                    surfaces_in_fall_range_without_jump_distance_result_set, \
                    [top_left, top_right, bottom_right, bottom_left], \
                    all_possible_surfaces_set)
            
        SurfaceSide.FLOOR:
            # Only expand calculate the jump-distance results, if the corresponding result set is
            # given.
            if surfaces_in_fall_range_with_jump_distance_result_set != null:
                top_left = origin_surface.first_point - offset_for_jump_distance
                top_right = origin_surface.last_point + offset_for_jump_distance
                bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                _get_surfaces_intersecting_polygon( \
                        surfaces_in_fall_range_with_jump_distance_result_set, \
                        [top_left, top_right, bottom_right, bottom_left], \
                        all_possible_surfaces_set)
                
                # Limit the possible surfaces for the following without-jump-distance calculation
                # to be a subset of the with-jump-distance result.
                all_possible_surfaces_set = surfaces_in_fall_range_with_jump_distance_result_set
            
            top_left = origin_surface.first_point - \
                    offset_for_acceleration_to_terminal_velocity
            top_right = origin_surface.last_point + \
                    offset_for_acceleration_to_terminal_velocity
            bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            _get_surfaces_intersecting_polygon( \
                    surfaces_in_fall_range_without_jump_distance_result_set, \
                    [top_left, top_right, bottom_right, bottom_left], \
                    all_possible_surfaces_set)
            
        _:
            Utils.error()

# This is only an approximation, since it only considers the end points of the surface rather than
# each segment of the surface polyline.
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

# This is only an approximation, since it only considers the end points of the surface rather than
# each segment of the surface polyline.
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
