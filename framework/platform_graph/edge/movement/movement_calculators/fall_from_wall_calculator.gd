extends EdgeMovementCalculator
class_name FallFromWallCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/movement/models/movement_calculation_overall_params.gd")

const NAME := "FallFromWallCalculator"

func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and (surface.side == SurfaceSide.LEFT_WALL or \
            surface.side == SurfaceSide.RIGHT_WALL)

func get_all_edges_from_surface(collision_params: CollisionCalcParams, edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, surfaces_in_jump_range_set: Dictionary, \
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
    
    var top_jump_position := MovementUtils.create_position_from_target_point( \
            origin_top_point, origin_surface, movement_params.collider_half_width_height)
    var bottom_jump_position := MovementUtils.create_position_from_target_point( \
            origin_bottom_point, origin_surface, movement_params.collider_half_width_height)
    var jump_positions := [top_jump_position, bottom_jump_position]
    
    var land_positions: Array
    var terminals: Array
    var instructions: MovementInstructions
    var edge: FallFromWallEdge
    var overall_calc_params: MovementCalcOverallParams
    
    for destination_surface in surfaces_in_fall_range_set:
        if origin_surface == destination_surface:
            # We don't need to calculate edges for the degenerate case.
            continue
        
        land_positions = MovementUtils.get_all_jump_land_positions_from_surface( \
                movement_params, destination_surface, origin_surface.vertices, \
                origin_surface.bounding_box, origin_surface.side)
        
        for jump_position in jump_positions:
            for land_position in land_positions:
                ###################################################################################
                # Allow for debug mode to limit the scope of what's calculated.
                if EdgeMovementCalculator.should_skip_edge_calculation(debug_state, \
                        origin_surface, destination_surface, jump_position, land_position, \
                        jump_positions, land_positions):
                    continue
                ###################################################################################
                
                overall_calc_params = EdgeMovementCalculator.create_movement_calc_overall_params( \
                        collision_params, jump_position.surface, jump_position.target_point, \
                        land_position.surface, land_position.target_point, false, velocity_start, \
                        false, false)
                if overall_calc_params == null:
                    continue
                
                ###################################################################################
                # Record some extra debug state when we're limiting calculations to a single edge.
                if debug_state.in_debug_mode and debug_state.has("limit_parsing") and \
                        debug_state.limit_parsing.has("edge") != null:
                    overall_calc_params.in_debug_mode = true
                ###################################################################################
                
                var vertical_step := \
                        VerticalMovementUtils.calculate_vertical_step(overall_calc_params)
                if vertical_step == null:
                    continue
                
                var step_calc_params := MovementCalcStepParams.new( \
                        overall_calc_params.origin_constraint, \
                        overall_calc_params.destination_constraint, vertical_step, \
                        overall_calc_params, null, null)
                
                var calc_results := MovementStepUtils.calculate_steps_from_constraint( \
                        overall_calc_params, step_calc_params)
                if calc_results == null:
                    continue
                
                edge = FallFromWallEdge.new(jump_position, land_position, calc_results)
                
                # FIXME: ---------- Remove?
                if Utils.IN_DEV_MODE:
                    MovementInstructionsUtils.test_instructions( \
                            edge.instructions, overall_calc_params, calc_results)
                
                if edge != null:
                    # Can reach land position from jump position.
                    edges_result.push_back(edge)
                    # For efficiency, only compute one edge per surface pair.
                    break
            
            if edge != null:
                # For efficiency, only compute one edge per surface pair.
                edge = null
                break
