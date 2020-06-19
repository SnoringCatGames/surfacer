extends EdgeCalculator
class_name FallFromWallCalculator

const NAME := "FallFromWallCalculator"
const EDGE_TYPE := EdgeType.FALL_FROM_WALL_EDGE
const IS_A_JUMP_CALCULATOR := false

func _init().( \
        NAME, \
        EDGE_TYPE, \
        IS_A_JUMP_CALCULATOR) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and (surface.side == SurfaceSide.LEFT_WALL or \
            surface.side == SurfaceSide.RIGHT_WALL)

func get_all_inter_surface_edges_from_surface( \
        inter_surface_edges_results: Array, \
        collision_params: CollisionCalcParams, \
        origin_surface: Surface, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary) -> void:
    var debug_params := collision_params.debug_params
    var movement_params := collision_params.movement_params
    var velocity_start := _get_start_velocity( \
            movement_params, \
            origin_surface)
    var jump_positions := _get_jump_positions( \
            movement_params, \
            origin_surface)
    
    var landing_trajectories: Array
    var edge: FallFromWallEdge
    
    for jump_position in jump_positions:
        #######################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if EdgeCalculator.should_skip_edge_calculation( \
                debug_params, \
                jump_position, \
                null):
            continue
        #######################################################################
        
        FallMovementUtils.find_landing_trajectories_to_any_surface( \
                inter_surface_edges_results, \
                collision_params, \
                surfaces_in_fall_range_set, \
                jump_position, \
                velocity_start, \
                self, \
                true)
        
        for inter_surface_edges_result in inter_surface_edges_results:
            for calc_result in inter_surface_edges_result.edge_calc_results:
                edge = _create_edge_from_calc_results( \
                        true, \
                        calc_result)
                inter_surface_edges_result.valid_edges.push_back(edge)

func calculate_edge( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: PositionAlongSurface, \
        velocity_start := Vector2.INF, \
        needs_extra_jump_duration := false, \
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    edge_result_metadata = \
            edge_result_metadata if \
            edge_result_metadata != null else \
            EdgeCalcResultMetadata.new(false, false)
    var calc_result: EdgeCalcResult = \
            FallMovementUtils.find_landing_trajectory_between_positions( \
                    edge_result_metadata, \
                    collision_params, \
                    position_start, \
                    position_end, \
                    velocity_start, \
                    needs_extra_wall_land_horizontal_speed)
    if calc_result != null:
        return _create_edge_from_calc_results( \
                edge_result_metadata.records_profile, \
                calc_result)
    else:
        return null

func optimize_edge_jump_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        previous_velocity_end_x: float, \
        previous_edge: IntraSurfaceEdge, \
        edge: Edge) -> void:
    assert(edge is FallFromWallEdge)
    
    var is_wall_surface := \
            previous_edge.start_surface != null and \
            (previous_edge.start_surface.side == SurfaceSide.LEFT_WALL or \
            previous_edge.start_surface.side == SurfaceSide.RIGHT_WALL)
    assert(is_wall_surface)
    
    EdgeCalculator.optimize_edge_jump_position_for_path_helper( \
            collision_params, \
            path, \
            edge_index, \
            previous_velocity_end_x, \
            previous_edge, \
            edge, \
            self)

func optimize_edge_land_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        edge: Edge, \
        next_edge: IntraSurfaceEdge) -> void:
    assert(edge is FallFromWallEdge)
    
    EdgeCalculator.optimize_edge_land_position_for_path_helper( \
            collision_params, \
            path, \
            edge_index, \
            edge, \
            next_edge, \
            self)

func _create_edge_from_calc_results( \
        records_profile: bool, \
        calc_result: EdgeCalcResult) -> FallFromWallEdge:
    var jump_position := calc_result.edge_calc_params.origin_position
    var land_position := calc_result.edge_calc_params.destination_position
    
    var instructions := _calculate_instructions( \
            records_profile, \
            jump_position, \
            land_position, \
            calc_result)
    
    var trajectory := \
            EdgeTrajectoryUtils.calculate_trajectory_from_calculation_steps( \
                    records_profile, \
                    calc_result, \
                    instructions)
    
    var velocity_end: Vector2 = \
            calc_result.horizontal_steps.back().velocity_step_end
    
    return FallFromWallEdge.new( \
            self, \
            jump_position, \
            land_position, \
            velocity_end, \
            calc_result.edge_calc_params \
                    .needs_extra_wall_land_horizontal_speed, \
            calc_result.edge_calc_params.movement_params, \
            instructions, \
            trajectory)

static func _get_start_velocity( \
        movement_params: MovementParams, \
        origin_surface: Surface) -> Vector2:
    return Vector2( \
            movement_params.wall_fall_horizontal_boost * \
                    origin_surface.normal.x, \
            0.0)

static func _get_jump_positions( \
        movement_params: MovementParams, \
        origin_surface: Surface) -> Array:
    # TODO: Update this to allow other mid-point jump-positions, which may be
    #       closer and more efficient than just the surface-end points.
    var origin_top_point := Vector2.INF
    var origin_bottom_point := Vector2.INF
    if origin_surface.side == SurfaceSide.LEFT_WALL:
        origin_top_point = origin_surface.first_point
        origin_bottom_point = origin_surface.last_point
    else:
        origin_top_point = origin_surface.last_point
        origin_bottom_point = origin_surface.first_point
    var top_jump_position := \
            MovementUtils.create_position_offset_from_target_point( \
                    origin_top_point, \
                    origin_surface, \
                    movement_params.collider_half_width_height)
    var bottom_jump_position := \
            MovementUtils.create_position_offset_from_target_point( \
                    origin_bottom_point, \
                    origin_surface, \
                    movement_params.collider_half_width_height)
    return [top_jump_position, bottom_jump_position]

static func _calculate_instructions( \
        records_profile: bool, \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        calc_result: EdgeCalcResult) -> EdgeInstructions:
    assert(start.surface.side == SurfaceSide.LEFT_WALL || \
            start.surface.side == SurfaceSide.RIGHT_WALL)
    
    # Calculate the fall-trajectory instructions.
    var instructions := EdgeInstructionsUtils \
            .convert_calculation_steps_to_movement_instructions( \
                    records_profile, \
                    calc_result, \
                    false, \
                    end.surface.side)
    
    # Calculate the wall-release instructions.
    var sideways_input_key := \
            "move_right" if \
            start.surface.side == SurfaceSide.LEFT_WALL else \
            "move_left"
    var outward_press := EdgeInstruction.new( \
            sideways_input_key, \
            0.0, \
            true)
    var outward_release := EdgeInstruction.new( \
            sideways_input_key, \
            0.001, \
            false)
    instructions.instructions.push_front(outward_release)
    instructions.instructions.push_front(outward_press)
    
    return instructions
