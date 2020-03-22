extends EdgeMovementCalculator
class_name FallFromWallCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/calculation_models/movement_calculation_overall_params.gd")

const NAME := "FallFromWallCalculator"

func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and (surface.side == SurfaceSide.LEFT_WALL or \
            surface.side == SurfaceSide.RIGHT_WALL)

func get_all_edges_from_surface( \
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
            
            edge = _create_edge_from_calc_results(calc_results, jump_position)
            edges_result.push_back(edge)

static func _create_edge_from_calc_results(calc_results: MovementCalcResults, \
        jump_position: PositionAlongSurface) -> FallFromWallEdge:
    var land_position := calc_results.overall_calc_params.destination_position
    var instructions := _calculate_instructions( \
            jump_position, \
            land_position, \
            calc_results)
    var velocity_end: Vector2 = calc_results.horizontal_steps.back().velocity_step_end
    return FallFromWallEdge.new( \
            jump_position, \
            land_position, \
            velocity_end, \
            calc_results.overall_calc_params.movement_params, \
            instructions)

static func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface, calc_results: MovementCalcResults) -> MovementInstructions:
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

static func optimize_edge_for_approach( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        previous_velocity_end_x: float, \
        previous_edge: IntraSurfaceEdge, \
        edge: JumpFromSurfaceToSurfaceEdge, \
        in_debug_mode: bool) -> void:
    # TODO: Refactor this to use a true binary search. Right now it is similar, but we never
    #       move backward once we find a working jump.
    var fall_off_ratios := [0.0, 0.5, 0.75, 0.875]
    
    var movement_params := collision_params.movement_params
    
    var previous_edge_displacement := previous_edge.end - previous_edge.start
    
    var fall_off_position: PositionAlongSurface
    var velocity_start: Vector2
    var calc_results: MovementCalcResults
    var optimized_edge: FallFromWallEdge
    
    for i in range(fall_off_ratios.size()):
        if fall_off_ratios[i] == 0.0:
            fall_off_position = previous_edge.start_position_along_surface
        else:
            fall_off_position = MovementUtils.create_position_offset_from_target_point( \
                    Vector2(0.0, previous_edge.start.y + \
                            previous_edge_displacement.y * fall_off_ratios[i]), \
                    previous_edge.start_surface, \
                    movement_params.collider_half_width_height)
        
        velocity_start = Vector2.ZERO
        
        calc_results = FallMovementUtils.find_landing_trajectory_between_positions( \
                fall_off_position, \
                edge.end_position_along_surface, \
                velocity_start, \
                collision_params)
        
        optimized_edge = _create_edge_from_calc_results(calc_results, fall_off_position)
        
        if optimized_edge != null:
            optimized_edge.is_bespoke_for_path = true
            
            previous_edge = IntraSurfaceEdge.new( \
                    previous_edge.start_position_along_surface, \
                    fall_off_position, \
                    Vector2.ZERO, \
                    movement_params)
            
            path.edges[edge_index] = previous_edge
            path.edges[edge_index + 1] = optimized_edge
            
            return
