class_name JumpFromSurfaceToAirCalculator
extends EdgeCalculator

const NAME := "JumpFromSurfaceToAirCalculator"
const EDGE_TYPE := EdgeType.JUMP_FROM_SURFACE_TO_AIR_EDGE
const IS_A_JUMP_CALCULATOR := true

func _init().( \
        NAME,
        EDGE_TYPE,
        IS_A_JUMP_CALCULATOR) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null

func get_all_inter_surface_edges_from_surface( \
        inter_surface_edges_results: Array,
        collision_params: CollisionCalcParams,
        origin_surface: Surface,
        surfaces_in_fall_range_set: Dictionary,
        surfaces_in_jump_range_set: Dictionary) -> void:
    Gs.logger.error("JumpFromSurfaceToAirCalculator" + \
            ".get_all_inter_surface_edges_from_surface should not be called")

func calculate_edge( \
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        velocity_start := Vector2.INF,
        needs_extra_jump_duration := false,
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    if velocity_start == Vector2.INF:
        var is_moving_leftward := position_end.target_point.x - \
                position_start.target_point.x < 0.0
        velocity_start = EdgeCalculator.get_velocity_start( \
                collision_params.movement_params,
                position_start.surface,
                true,
                is_moving_leftward)
    
    edge_result_metadata = \
            edge_result_metadata if \
            edge_result_metadata != null else \
            EdgeCalcResultMetadata.new(false, false)
    
    var edge_calc_params := EdgeCalculator.create_edge_calc_params( \
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
        return null
    
    var calc_result := EdgeStepUtils.calculate_steps_with_new_jump_height( \
            edge_result_metadata,
            edge_calc_params,
            null,
            null)
    if calc_result == null:
        return null
    
    var instructions := EdgeInstructionsUtils \
            .convert_calculation_steps_to_movement_instructions( \
                    false,
                    collision_params,
                    calc_result,
                    true,
                    SurfaceSide.NONE)
    var trajectory := \
            EdgeTrajectoryUtils.calculate_trajectory_from_calculation_steps( \
                    false,
                    collision_params,
                    calc_result,
                    instructions)
    
    var velocity_end: Vector2 = \
            calc_result.horizontal_steps.back().velocity_step_end
    
    var edge := JumpFromSurfaceToAirEdge.new( \
            self,
            position_start,
            position_end,
            velocity_start,
            velocity_end,
            needs_extra_jump_duration,
            collision_params.movement_params,
            instructions,
            trajectory,
            calc_result.edge_calc_result_type)
    
    return edge

func optimize_edge_jump_position_for_path( \
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        edge_index: int,
        previous_velocity_end_x: float,
        previous_edge: IntraSurfaceEdge,
        edge: Edge) -> void:
    assert(edge is JumpFromSurfaceToAirEdge)
    
    EdgeCalculator.optimize_edge_jump_position_for_path_helper( \
            collision_params,
            path,
            edge_index,
            previous_velocity_end_x,
            previous_edge,
            edge,
            self)
