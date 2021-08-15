class_name EdgeCalculator
extends Reference
## An EdgeCalculator calculates possible edges between certain types of edge
## pairs.
## For example, JumpFromSurfaceCalculator calculates edges that start from a
## position along a surfacer, but JumpFromSurfaceCalculator edges may end
## either along a surface or in the air.


# This is the minimum speed that we require edge calculations to have at the
# end of their jump trajectory when landing on a wall surface.
const MIN_LAND_ON_WALL_SPEED := 50.0

# The minimum land-on-wall horizontal speed is multiplied by this value when
# the character is likely to need more speed in order to land on the wall. In
# particular, this is used for positions at the bottom of walls, where the
# character might otherwise fall short.
const MIN_LAND_ON_WALL_EXTRA_SPEED_RATIO := 2.0

var name: String

# EdgeType
var edge_type: int

var is_a_jump_calculator: bool


func _init(
        name: String,
        edge_type: int,
        is_a_jump_calculator: bool) -> void:
    self.name = name
    self.edge_type = edge_type
    self.is_a_jump_calculator = is_a_jump_calculator


func get_can_traverse_from_surface(surface: Surface) -> bool:
    Sc.logger.error(
            "Abstract EdgeCalculator.get_can_traverse_from_surface is not " +
            "implemented")
    return false


func get_all_inter_surface_edges_from_surface(
        inter_surface_edges_results: Array,
        collision_params: CollisionCalcParams,
        origin_surface: Surface,
        surfaces_in_fall_range_set: Dictionary,
        surfaces_in_jump_range_set: Dictionary) -> void:
    Sc.logger.error(
            "Abstract EdgeCalculator" +
            ".get_all_inter_surface_edges_from_surface is not implemented")


func calculate_edge(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        velocity_start := Vector2.INF,
        needs_extra_jump_duration := false,
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    Sc.logger.error(
            "Abstract EdgeCalculator.calculate_edge is not implemented")
    return null


func optimize_edge_jump_position_for_path(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        edge_index: int,
        previous_velocity_end_x: float,
        previous_edge: IntraSurfaceEdge,
        edge: Edge) -> void:
    # Do nothing by default. Sub-classes implement this as needed.
    pass


func optimize_edge_land_position_for_path(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        edge_index: int,
        edge: Edge,
        next_edge: IntraSurfaceEdge) -> void:
    # Do nothing by default. Sub-classes implement this as needed.
    pass


static func create_edge_calc_params(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        origin_position: PositionAlongSurface,
        destination_position: PositionAlongSurface,
        can_hold_jump_button: bool,
        velocity_start: Vector2,
        needs_extra_jump_duration: bool,
        needs_extra_wall_land_horizontal_speed: bool) -> EdgeCalcParams:
    Sc.profiler.start(
            "create_edge_calc_params",
            collision_params.thread_id)
    
    # When landing on a wall, ensure that we end with velocity moving into the
    # wall.
    var velocity_end_min_x := INF
    var velocity_end_max_x := INF
    if destination_position.surface != null:
        var min_land_on_wall_speed := \
                MIN_LAND_ON_WALL_SPEED * \
                        MIN_LAND_ON_WALL_EXTRA_SPEED_RATIO if \
                needs_extra_wall_land_horizontal_speed else \
                MIN_LAND_ON_WALL_SPEED
        if destination_position.side == SurfaceSide.LEFT_WALL:
            velocity_end_min_x = -collision_params.movement_params \
                    .max_horizontal_speed_default
            velocity_end_max_x = -min_land_on_wall_speed
        if destination_position.side == SurfaceSide.RIGHT_WALL:
            velocity_end_min_x = min_land_on_wall_speed
            velocity_end_max_x = collision_params.movement_params \
                    .max_horizontal_speed_default
    
    var terminals := WaypointUtils.create_terminal_waypoints(
            edge_result_metadata,
            origin_position,
            destination_position,
            collision_params.movement_params,
            can_hold_jump_button,
            velocity_start,
            velocity_end_min_x,
            velocity_end_max_x,
            needs_extra_jump_duration)
    if terminals.empty():
        # Cannot reach destination from origin (edge_result_metadata already
        # updated).
        Sc.profiler.stop_with_optional_metadata(
                "create_edge_calc_params",
                collision_params.thread_id,
                edge_result_metadata)
        return null
    
    var edge_calc_params := EdgeCalcParams.new(
            collision_params,
            origin_position,
            destination_position,
            terminals[0],
            terminals[1],
            velocity_start,
            needs_extra_jump_duration,
            needs_extra_wall_land_horizontal_speed,
            can_hold_jump_button)
    
    Sc.profiler.stop_with_optional_metadata(
            "create_edge_calc_params",
            collision_params.thread_id,
            edge_result_metadata)
    return edge_calc_params


# Does some cheap checks to see if we should more expensive edge calculations
# for the given jump/land pair.
static func broad_phase_check(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        jump_land_positions: JumpLandPositions,
        other_valid_jump_land_position_results: Array,
        allows_close_jump_positions: bool) -> bool:
    Sc.profiler.start(
            "edge_calc_broad_phase_check",
            collision_params.thread_id)
    
    ###########################################################################
    # Allow for debug mode to limit the scope of what's calculated.
    if should_skip_edge_calculation(
            collision_params.debug_params,
            jump_land_positions.jump_position,
            jump_land_positions.land_position,
            jump_land_positions.velocity_start):
        if edge_result_metadata != null:
            edge_result_metadata.edge_calc_result_type = \
                    EdgeCalcResultType.SKIPPED_FOR_DEBUGGING
        Sc.profiler.stop(
                "edge_calc_broad_phase_check",
                collision_params.thread_id)
        return false
    ###########################################################################
    
    if jump_land_positions.less_likely_to_be_valid and \
            collision_params \
                    .movement_params.skips_less_likely_jump_land_positions:
        if edge_result_metadata != null:
            edge_result_metadata.edge_calc_result_type = \
                    EdgeCalcResultType.LESS_LIKELY_TO_BE_VALID
        Sc.profiler.stop(
                "edge_calc_broad_phase_check",
                collision_params.thread_id)
        return false
    
    if !jump_land_positions.is_far_enough_from_others(
            collision_params.movement_params,
            other_valid_jump_land_position_results,
            !allows_close_jump_positions,
            true):
        # We've already found a valid edge with a land position that's
        # close enough to this land position.
        if edge_result_metadata != null:
            edge_result_metadata.edge_calc_result_type = \
                    EdgeCalcResultType.CLOSE_TO_PREVIOUS_EDGE
        Sc.profiler.stop(
                "edge_calc_broad_phase_check",
                collision_params.thread_id)
        return false
    
    Sc.profiler.stop(
            "edge_calc_broad_phase_check",
            collision_params.thread_id)
    return true


static func should_skip_edge_calculation(
        debug_params: Dictionary,
        jump_position_or_surface,
        land_position_or_surface,
        velocity_start) -> bool:
    if debug_params.has("limit_parsing") and \
            debug_params.limit_parsing.has("edge"):
        var jump_surface: Surface = \
                jump_position_or_surface.surface if \
                jump_position_or_surface is PositionAlongSurface else \
                jump_position_or_surface
        var land_surface: Surface = \
                land_position_or_surface.surface if \
                land_position_or_surface is PositionAlongSurface else \
                land_position_or_surface
        var jump_target_projection_point: Vector2 = \
                jump_position_or_surface.target_projection_onto_surface if \
                jump_position_or_surface is PositionAlongSurface else \
                Vector2.INF
        var land_target_projection_point: Vector2 = \
                land_position_or_surface.target_projection_onto_surface if \
                land_position_or_surface is PositionAlongSurface else \
                Vector2.INF
        
        if debug_params.limit_parsing.edge.has("origin"):
            var debug_origin: Dictionary = \
                    debug_params.limit_parsing.edge.origin
            var origin_epsilon: float = \
                    debug_origin.epsilon if \
                    debug_origin.has("epsilon") else \
                    10.0
            
            # Ignore this if we expect to know the jump surface, but don't.
            if jump_surface != null:
                if (debug_origin.has("surface_side") and \
                        debug_origin.surface_side != jump_surface.side) or \
                        (debug_origin.has("surface_start_vertex") and \
                                !Sc.geometry.are_points_equal_with_epsilon(
                                        debug_origin.surface_start_vertex,
                                        jump_surface.first_point,
                                        origin_epsilon)) or \
                        (debug_origin.has("surface_end_vertex") and \
                                !Sc.geometry.are_points_equal_with_epsilon(
                                        debug_origin.surface_end_vertex,
                                        jump_surface.last_point,
                                        origin_epsilon)):
                    # Ignore anything except the origin surface that we're
                    # debugging.
                    return true
            
            if debug_origin.has("position") and \
                    jump_target_projection_point != Vector2.INF:
                if !Sc.geometry.are_points_equal_with_epsilon(
                        jump_target_projection_point,
                        debug_origin.position,
                        origin_epsilon):
                    # Ignore anything except the jump position that we're
                    # debugging.
                    return true
        
        if debug_params.limit_parsing.edge.has("destination"):
            var debug_destination: Dictionary = \
                    debug_params.limit_parsing.edge.destination
            var destination_epsilon: float = \
                    debug_destination.epsilon if \
                    debug_destination.has("epsilon") else \
                    10.0
            
            # Ignore this if we expect to know the land surface, but don't.
            if land_surface != null:
                if (debug_destination.has("surface_side") and \
                        debug_destination.surface_side != \
                                land_surface.side) or \
                        (debug_destination.has("surface_start_vertex") and \
                                !Sc.geometry.are_points_equal_with_epsilon(
                                        debug_destination.surface_start_vertex,
                                        land_surface.first_point,
                                        destination_epsilon)) or \
                        (debug_destination.has("surface_end_vertex") and \
                                !Sc.geometry.are_points_equal_with_epsilon(
                                        debug_destination.surface_end_vertex,
                                        land_surface.last_point,
                                        destination_epsilon)):
                    # Ignore anything except the destination surface that we're
                    # debugging.
                    return true
            
            if debug_destination.has("position") and \
                    land_target_projection_point != Vector2.INF:
                if !Sc.geometry.are_points_equal_with_epsilon(
                        land_target_projection_point,
                        debug_destination.position,
                        destination_epsilon):
                    # Ignore anything except the land position that we're
                    # debugging.
                    return true
        
        if debug_params.limit_parsing.edge.has("velocity_start") and \
                velocity_start != null:
                if !Sc.geometry.are_points_equal_with_epsilon(
                        velocity_start,
                        debug_params.limit_parsing.edge.velocity_start,
                        10.0):
                    # Ignore anything except the start velocity that we're
                    # debugging.
                    return true
    
    return false


static func optimize_edge_jump_position_for_path_helper(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        edge_index: int,
        previous_velocity_end_x: float,
        previous_edge: IntraSurfaceEdge,
        edge: Edge,
        edge_calculator: EdgeCalculator) -> void:
    # TODO: Refactor this to use a true binary search. Right now it is similar,
    #       but we never move backward once we find a working jump.
    var jump_ratios := [0.0, 0.5, 0.75, 0.875]
    
    var movement_params := collision_params.movement_params
    
    var previous_edge_displacement := \
            previous_edge.get_end() - previous_edge.get_start()
    
    var is_horizontal_surface := \
            previous_edge.get_start_surface() != null and \
            (previous_edge.get_start_surface().side == SurfaceSide.FLOOR or \
            previous_edge.get_start_surface().side == SurfaceSide.CEILING)
    
    if is_horizontal_surface:
        # Jumping from a floor or ceiling.
        
        var is_already_exceeding_max_speed_toward_displacement := \
                (previous_edge_displacement.x >= 0.0 and \
                        previous_velocity_end_x > \
                        movement_params.max_horizontal_speed_default) or \
                (previous_edge_displacement.x <= 0.0 and \
                        previous_velocity_end_x < \
                        -movement_params.max_horizontal_speed_default)
        
        var acceleration_x := movement_params.walk_acceleration if \
                previous_edge_displacement.x >= 0.0 else \
                -movement_params.walk_acceleration
        
        for i in jump_ratios.size():
            var jump_position: PositionAlongSurface
            if jump_ratios[i] == 0.0:
                jump_position = previous_edge.start_position_along_surface
            else:
                jump_position = PositionAlongSurfaceFactory \
                        .create_position_offset_from_target_point(
                                Vector2(previous_edge.get_start().x + \
                                        previous_edge_displacement.x * \
                                        jump_ratios[i],
                                        0.0),
                                previous_edge.get_start_surface(),
                                movement_params.collider_half_width_height)
            
            # Calculate the start velocity to use according to the available
            # ramp-up distance and max speed.
            var velocity_start_x: float = MovementUtils \
                    .calculate_velocity_end_for_displacement(
                            jump_position.target_point.x - \
                                    previous_edge.get_start().x,
                            previous_velocity_end_x,
                            acceleration_x,
                            movement_params.max_horizontal_speed_default)
            var velocity_start_y := movement_params.jump_boost
            var velocity_start = Vector2(velocity_start_x, velocity_start_y)
            
            var optimized_edge := edge_calculator.calculate_edge(
                    null,
                    collision_params,
                    jump_position,
                    edge.end_position_along_surface,
                    velocity_start,
                    edge.includes_extra_jump_duration,
                    edge.includes_extra_wall_land_horizontal_speed)
            
            if optimized_edge != null:
                optimized_edge.is_optimized_for_path = true
                
                previous_edge = IntraSurfaceEdge.new(
                        previous_edge.start_position_along_surface,
                        jump_position,
                        Vector2(previous_velocity_end_x, 0.0),
                        movement_params)
                
                path.edges[edge_index - 1] = previous_edge
                path.edges[edge_index] = optimized_edge
                
                return
        
    else:
        # Jumping from a wall.
        
        for i in jump_ratios.size():
            var jump_position: PositionAlongSurface
            if jump_ratios[i] == 0.0:
                jump_position = previous_edge.start_position_along_surface
            else:
                jump_position = PositionAlongSurfaceFactory \
                        .create_position_offset_from_target_point(
                                Vector2(0.0,
                                        previous_edge.get_start().y + \
                                        previous_edge_displacement.y * \
                                        jump_ratios[i]),
                                previous_edge.get_start_surface(),
                                movement_params.collider_half_width_height)
            
            var velocity_start := JumpLandPositionsUtils.get_velocity_start(
                    movement_params,
                    jump_position.surface,
                    edge_calculator.is_a_jump_calculator)
            
            var optimized_edge := edge_calculator.calculate_edge(
                    null,
                    collision_params,
                    jump_position,
                    edge.end_position_along_surface,
                    velocity_start,
                    edge.includes_extra_jump_duration,
                    edge.includes_extra_wall_land_horizontal_speed)
            
            if optimized_edge != null:
                optimized_edge.is_optimized_for_path = true
                
                previous_edge = IntraSurfaceEdge.new(
                        previous_edge.start_position_along_surface,
                        jump_position,
                        Vector2.ZERO,
                        movement_params)
                
                path.edges[edge_index - 1] = previous_edge
                path.edges[edge_index] = optimized_edge
                
                return


static func optimize_edge_land_position_for_path_helper(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        edge_index: int,
        edge: Edge,
        next_edge: IntraSurfaceEdge,
        edge_calculator: EdgeCalculator) -> void:
    # TODO: Refactor this to use a true binary search. Right now it is similar,
    #       but we never move backward once we find a working land.
    var land_ratios := [1.0, 0.5, 0.25, 0.125]
    
    var movement_params := collision_params.movement_params
    
    var next_edge_displacement := next_edge.get_end() - next_edge.get_start()
    
    var is_horizontal_surface := \
            next_edge.get_start_surface() != null and \
            (next_edge.get_start_surface().side == SurfaceSide.FLOOR or \
            next_edge.get_start_surface().side == SurfaceSide.CEILING)
    
    if is_horizontal_surface:
        # Landing on a floor or ceiling.
        
        for i in land_ratios.size():
            var land_position: PositionAlongSurface
            if land_ratios[i] == 1.0:
                land_position = next_edge.end_position_along_surface
            else:
                land_position = PositionAlongSurfaceFactory \
                        .create_position_offset_from_target_point(
                                Vector2(next_edge.get_start().x + \
                                        next_edge_displacement.x * \
                                        land_ratios[i],
                                        0.0),
                                next_edge.get_start_surface(),
                                movement_params.collider_half_width_height)
            
            var optimized_edge := edge_calculator.calculate_edge(
                    null,
                    collision_params,
                    edge.start_position_along_surface,
                    land_position,
                    edge.velocity_start,
                    edge.includes_extra_jump_duration,
                    false)
            
            if optimized_edge != null:
                optimized_edge.is_optimized_for_path = true
                
                next_edge = IntraSurfaceEdge.new(
                        land_position,
                        next_edge.end_position_along_surface,
                        optimized_edge.velocity_end,
                        movement_params)
                
                path.edges[edge_index] = optimized_edge
                path.edges[edge_index + 1] = next_edge
                
                return
        
    else:
        # Landing on a wall.
        
        for i in land_ratios.size():
            var land_position: PositionAlongSurface
            if land_ratios[i] == 1.0:
                land_position = next_edge.end_position_along_surface
            else:
                land_position = PositionAlongSurfaceFactory \
                        .create_position_offset_from_target_point(
                                Vector2(0.0, next_edge.get_start().y + \
                                        next_edge_displacement.y * \
                                        land_ratios[i]),
                                next_edge.get_start_surface(),
                                movement_params.collider_half_width_height)
            
            if JumpLandPositionsUtils.is_land_position_close_to_wall_bottom(
                    land_position):
                # If we're too close to the wall bottom, than this and future
                # possible optimized land positions aren't valid.
                return
            
            var optimized_edge := edge_calculator.calculate_edge(
                    null,
                    collision_params,
                    edge.start_position_along_surface,
                    land_position,
                    edge.velocity_start,
                    edge.includes_extra_jump_duration,
                    edge.includes_extra_wall_land_horizontal_speed)
            
            if optimized_edge != null:
                optimized_edge.is_optimized_for_path = true
                
                next_edge = IntraSurfaceEdge.new(
                        land_position,
                        next_edge.end_position_along_surface,
                        Vector2.ZERO,
                        movement_params)
                
                path.edges[edge_index] = optimized_edge
                path.edges[edge_index + 1] = next_edge
                
                return
