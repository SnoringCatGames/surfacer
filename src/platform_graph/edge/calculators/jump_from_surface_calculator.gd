class_name JumpFromSurfaceCalculator
extends EdgeCalculator


const NAME := "JumpFromSurfaceCalculator"
const EDGE_TYPE := EdgeType.JUMP_FROM_SURFACE_EDGE
const IS_A_JUMP_CALCULATOR := true


func _init().(
        NAME,
        EDGE_TYPE,
        IS_A_JUMP_CALCULATOR) -> void:
    pass


func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null


func get_all_inter_surface_edges_from_surface(
        inter_surface_edges_results: Array,
        collision_params: CollisionCalcParams,
        origin_surface: Surface,
        surfaces_in_fall_range_set: Dictionary,
        surfaces_in_jump_range_set: Dictionary) -> void:
    var debug_params := collision_params.debug_params
    
    var jump_land_position_results_for_destination_surface := []
    
    for destination_surface in surfaces_in_jump_range_set:
        # This makes the assumption that traversing through any
        # fall-through/walk-through surface would be better handled by some
        # other Movement type, so we don't handle those cases here.
        
        #######################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if EdgeCalculator.should_skip_edge_calculation(
                debug_params,
                origin_surface,
                destination_surface,
                null):
            continue
        #######################################################################
        
        if origin_surface == destination_surface:
            # We don't need to calculate edges for the degenerate case.
            continue
        
        jump_land_position_results_for_destination_surface.clear()
        
        Sc.profiler.start(
                "calculate_jump_land_positions_for_surface_pair",
                collision_params.thread_id)
        var jump_land_positions_to_consider := JumpLandPositionsUtils \
                .calculate_jump_land_positions_for_surface_pair(
                        collision_params.movement_params,
                        origin_surface,
                        destination_surface)
        Sc.profiler.stop(
                "calculate_jump_land_positions_for_surface_pair",
                collision_params.thread_id)
        
        var inter_surface_edges_result := InterSurfaceEdgesResult.new(
                origin_surface,
                destination_surface,
                edge_type,
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
                    debug_params.limit_parsing.edge.origin.has(
                            "position") and \
                    debug_params.limit_parsing.edge.has("destination") and \
                    debug_params.limit_parsing.edge.destination.has("position")
            ###################################################################
            
            var edge_result_metadata := EdgeCalcResultMetadata.new(
                    records_calc_details,
                    true)
            
            if !EdgeCalculator.broad_phase_check(
                    edge_result_metadata,
                    collision_params,
                    jump_land_positions,
                    jump_land_position_results_for_destination_surface,
                    false):
                var failed_attempt := FailedEdgeAttempt.new(
                        jump_land_positions,
                        edge_result_metadata,
                        self)
                inter_surface_edges_result.failed_edge_attempts.push_back(
                        failed_attempt)
                continue
            
            var edge := calculate_edge(
                    edge_result_metadata,
                    collision_params,
                    jump_land_positions.jump_position,
                    jump_land_positions.land_position,
                    jump_land_positions.velocity_start,
                    jump_land_positions.needs_extra_jump_duration,
                    jump_land_positions.needs_extra_wall_land_horizontal_speed)
            
            if edge != null:
                # Can reach land position from jump position.
                inter_surface_edges_result.valid_edges.push_back(edge)
                edge = null
                jump_land_position_results_for_destination_surface.push_back(
                        jump_land_positions)
            else:
                var failed_attempt := FailedEdgeAttempt.new(
                        jump_land_positions,
                        edge_result_metadata,
                        self)
                inter_surface_edges_result.failed_edge_attempts.push_back(
                        failed_attempt)


func calculate_edge(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        velocity_start := Vector2.INF,
        needs_extra_jump_duration := false,
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    edge_result_metadata = \
            edge_result_metadata if \
            edge_result_metadata != null else \
            EdgeCalcResultMetadata.new(false, false)
    
    Sc.profiler.start(
            "calculate_jump_from_surface_edge",
            collision_params.thread_id)
    
    var edge_calc_params := EdgeCalculator.create_edge_calc_params(
            edge_result_metadata,
            collision_params,
            position_start,
            position_end,
            true,
            velocity_start,
            needs_extra_jump_duration,
            needs_extra_wall_land_horizontal_speed)
    if edge_calc_params == null:
        # Cannot reach destination from origin.
        Sc.profiler.stop_with_optional_metadata(
                "calculate_jump_from_surface_edge",
                collision_params.thread_id,
                edge_result_metadata)
        return null
    
    var edge := create_edge_from_edge_calc_params(
            edge_result_metadata,
            edge_calc_params)
    
    Sc.profiler.stop_with_optional_metadata(
            "calculate_jump_from_surface_edge",
            collision_params.thread_id,
            edge_result_metadata)
    return edge


func optimize_edge_jump_position_for_path(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        edge_index: int,
        previous_velocity_end_x: float,
        previous_edge: IntraSurfaceEdge,
        edge: Edge) -> void:
    assert(edge is JumpFromSurfaceEdge)
    
    EdgeCalculator.optimize_edge_jump_position_for_path_helper(
            collision_params,
            path,
            edge_index,
            previous_velocity_end_x,
            previous_edge,
            edge,
            self)


func optimize_edge_land_position_for_path(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        edge_index: int,
        edge: Edge,
        next_edge: IntraSurfaceEdge) -> void:
    assert(edge is JumpFromSurfaceEdge)
    
    EdgeCalculator.optimize_edge_land_position_for_path_helper(
            collision_params,
            path,
            edge_index,
            edge,
            next_edge,
            self)


func create_edge_from_edge_calc_params(
        edge_result_metadata: EdgeCalcResultMetadata,
        edge_calc_params: EdgeCalcParams) -> JumpFromSurfaceEdge:
    Sc.profiler.start(
            "calculate_jump_from_surface_steps",
            edge_calc_params.collision_params.thread_id)
    Sc.profiler.start(
            "narrow_phase_edge_calculation",
            edge_calc_params.collision_params.thread_id)
    var calc_result := EdgeStepUtils.calculate_steps_with_new_jump_height(
            edge_result_metadata,
            edge_calc_params,
            null,
            null)
    Sc.profiler.stop_with_optional_metadata(
            "narrow_phase_edge_calculation",
            edge_calc_params.collision_params.thread_id,
            edge_result_metadata)
    Sc.profiler.stop_with_optional_metadata(
            "calculate_jump_from_surface_steps",
            edge_calc_params.collision_params.thread_id,
            edge_result_metadata)
    if calc_result == null:
        # Unable to calculate a valid edge.
        return null
    
    assert(EdgeCalcResultType.get_is_valid(
            edge_result_metadata.edge_calc_result_type))
    
    var instructions := EdgeInstructionsUtils \
            .convert_calculation_steps_to_movement_instructions(
                    edge_result_metadata,
                    edge_calc_params.collision_params,
                    calc_result,
                    true,
                    edge_calc_params.destination_position.side)
    var trajectory := EdgeTrajectoryUtils \
            .calculate_trajectory_from_calculation_steps(
                    edge_result_metadata,
                    edge_calc_params.collision_params,
                    calc_result,
                    instructions)
    
    var velocity_end: Vector2 = \
            calc_result.horizontal_steps.back().velocity_step_end
    
    var edge := JumpFromSurfaceEdge.new(
            self,
            edge_calc_params.origin_position,
            edge_calc_params.destination_position,
            edge_calc_params.velocity_start,
            velocity_end,
            edge_calc_params.needs_extra_jump_duration,
            edge_calc_params.needs_extra_wall_land_horizontal_speed,
            edge_calc_params.movement_params,
            instructions,
            trajectory,
            calc_result.edge_calc_result_type,
            calc_result.vertical_step.time_peak_height)
    
    return edge
