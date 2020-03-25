extends EdgeMovementCalculator
class_name FallFromWallCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/calculation_models/movement_calculation_overall_params.gd")

const NAME := "FallFromWallCalculator"

func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and (surface.side == SurfaceSide.LEFT_WALL or \
            surface.side == SurfaceSide.RIGHT_WALL)

func get_all_inter_surface_edges_from_surface( \
        collision_params: CollisionCalcParams, \
        edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    var debug_state := collision_params.debug_state
    var movement_params := collision_params.movement_params
    var velocity_start := Vector2.ZERO
    
    var origin_top_point := Vector2.INF
    var origin_bottom_point := Vector2.INF
    if origin_surface.side == SurfaceSide.LEFT_WALL:
        origin_top_point = origin_surface.first_point
        origin_bottom_point = origin_surface.last_point
    else:
        origin_top_point = origin_surface.last_point
        origin_bottom_point = origin_surface.first_point
    
    var top_jump_position := MovementUtils.create_position_offset_from_target_point( \
            origin_top_point, \
            origin_surface, \
            movement_params.collider_half_width_height)
    var bottom_jump_position := MovementUtils.create_position_offset_from_target_point( \
            origin_bottom_point, \
            origin_surface, \
            movement_params.collider_half_width_height)
    var jump_positions := [top_jump_position, bottom_jump_position]
    
    var landing_surfaces_to_skip := {}
    var landing_trajectories: Array
    var edge: FallFromWallEdge
    
    for jump_position in jump_positions:
        ###################################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if EdgeMovementCalculator.should_skip_edge_calculation(debug_state, \
                jump_position, null):
            continue
        ###################################################################################
        
        landing_trajectories = FallMovementUtils.find_landing_trajectories_to_any_surface( \
                collision_params, \
                surfaces_in_fall_range_set, \
                jump_position, \
                velocity_start, \
                landing_surfaces_to_skip)
        
        for calc_results in landing_trajectories:
            landing_surfaces_to_skip[ \
                    calc_results.overall_calc_params.destination_position.surface] = true
            
            edge = _create_edge_from_calc_results(calc_results)
            edges_result.push_back(edge)

func calculate_edge( \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: PositionAlongSurface, \
        velocity_start := Vector2.INF, \
        in_debug_mode := false) -> Edge:
    var calc_results: MovementCalcResults = \
            FallMovementUtils.find_landing_trajectory_between_positions( \
                    position_start, \
                    position_end, \
                    velocity_start, \
                    collision_params)
    if calc_results != null:
        return _create_edge_from_calc_results(calc_results)
    else:
        return null

func optimize_edge_jump_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        previous_velocity_end_x: float, \
        previous_edge: IntraSurfaceEdge, \
        edge: Edge, \
        in_debug_mode: bool) -> void:
    assert(edge is FallFromWallEdge)
    
    var is_wall_surface := \
            previous_edge.start_surface != null and \
            (previous_edge.start_surface.side == SurfaceSide.LEFT_WALL or \
            previous_edge.start_surface.side == SurfaceSide.RIGHT_WALL)
    assert(is_wall_surface)
    
    EdgeMovementCalculator.optimize_edge_jump_position_for_path_helper( \
            collision_params, \
            path, \
            edge_index, \
            previous_velocity_end_x, \
            previous_edge, \
            edge, \
            in_debug_mode, \
            self)

func optimize_edge_land_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        edge: Edge, \
        next_edge: IntraSurfaceEdge, \
        in_debug_mode: bool) -> void:
    assert(edge is FallFromWallEdge)
    
    EdgeMovementCalculator.optimize_edge_land_position_for_path_helper( \
            collision_params, \
            path, \
            edge_index, \
            edge, \
            next_edge, \
            in_debug_mode, \
            self)

func _create_edge_from_calc_results(calc_results: MovementCalcResults) -> FallFromWallEdge:
    var jump_position := calc_results.overall_calc_params.origin_position
    var land_position := calc_results.overall_calc_params.destination_position
    
    var instructions := _calculate_instructions( \
            jump_position, \
            land_position, \
            calc_results)
    
    var trajectory := MovementTrajectoryUtils.calculate_trajectory_from_calculation_steps( \
            calc_results, \
            instructions)
    
    var velocity_end: Vector2 = calc_results.horizontal_steps.back().velocity_step_end
    
    return FallFromWallEdge.new( \
            self, \
            jump_position, \
            land_position, \
            velocity_end, \
            calc_results.overall_calc_params.movement_params, \
            instructions, \
            trajectory)

static func _calculate_instructions( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        calc_results: MovementCalcResults) -> MovementInstructions:
    assert(start.surface.side == SurfaceSide.LEFT_WALL || \
            start.surface.side == SurfaceSide.RIGHT_WALL)
    
    # Calculate the fall-trajectory instructions.
    var instructions := \
            MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
                    calc_results, \
                    false, \
                    end.surface.side)
    
    # Calculate the wall-release instructions.
    var sideways_input_key := \
            "move_right" if start.surface.side == SurfaceSide.LEFT_WALL else "move_left"
    var outward_press := MovementInstruction.new(sideways_input_key, 0.0, true)
    var outward_release := MovementInstruction.new(sideways_input_key, 0.001, false)
    instructions.instructions.push_front(outward_release)
    instructions.instructions.push_front(outward_press)
    
    return instructions
