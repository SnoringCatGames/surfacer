extends EdgeMovementCalculator
class_name JumpFromSurfaceToAirCalculator

const NAME := "JumpFromSurfaceToAirCalculator"
const EDGE_TYPE := EdgeType.JUMP_FROM_SURFACE_TO_AIR_EDGE
const IS_A_JUMP_CALCULATOR := true

func _init().( \
        NAME, \
        EDGE_TYPE, \
        IS_A_JUMP_CALCULATOR) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null

func get_all_inter_surface_edges_from_surface( \
        edges_result: Array, \
        failed_edge_attempts_result: Array, \
        collision_params: CollisionCalcParams, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    Utils.error("JumpFromSurfaceToAirCalculator.get_all_inter_surface_edges_from_surface " + \
            "should not be called")

func calculate_edge( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: PositionAlongSurface, \
        velocity_start := Vector2.INF, \
        needs_extra_jump_duration := false, \
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    if velocity_start == Vector2.INF:
        var is_moving_leftward := position_end.target_point.x - position_start.target_point.x < 0.0
        velocity_start = EdgeMovementCalculator.get_velocity_start( \
                collision_params.movement_params, \
                position_start.surface, \
                is_a_jump_calculator, \
                is_moving_leftward)
    
    edge_result_metadata = \
            edge_result_metadata if \
            edge_result_metadata != null else \
            EdgeCalcResultMetadata.new(false)
    
    var overall_calc_params := EdgeMovementCalculator.create_movement_calc_overall_params( \
            edge_result_metadata, \
            collision_params, \
            position_start, \
            position_end, \
            true, \
            velocity_start, \
            needs_extra_jump_duration, \
            needs_extra_wall_land_horizontal_speed)
    if overall_calc_params == null:
        # Cannot reach destination from origin.
        return null
    
    var calc_results := MovementStepUtils.calculate_steps_with_new_jump_height( \
            edge_result_metadata, \
            overall_calc_params, \
            null, \
            null)
    if calc_results == null:
        return null
    
    var instructions := \
            MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
                    calc_results, \
                    true, \
                    SurfaceSide.NONE)
    var trajectory := MovementTrajectoryUtils.calculate_trajectory_from_calculation_steps( \
            calc_results, \
            instructions)
    
    var velocity_end: Vector2 = calc_results.horizontal_steps.back().velocity_step_end
    
    var edge := JumpFromSurfaceToAirEdge.new( \
            self, \
            position_start, \
            position_end, \
            velocity_start, \
            velocity_end, \
            needs_extra_jump_duration, \
            collision_params.movement_params, \
            instructions, \
            trajectory)
    
    return edge

func optimize_edge_jump_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        previous_velocity_end_x: float, \
        previous_edge: IntraSurfaceEdge, \
        edge: Edge) -> void:
    assert(edge is JumpFromSurfaceToAirEdge)
    
    EdgeMovementCalculator.optimize_edge_jump_position_for_path_helper( \
            collision_params, \
            path, \
            edge_index, \
            previous_velocity_end_x, \
            previous_edge, \
            edge, \
            self)
