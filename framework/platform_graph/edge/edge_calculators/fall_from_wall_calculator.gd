extends EdgeMovementCalculator
class_name FallFromWallCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/calculation_models/movement_calculation_overall_params.gd")

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
    
    var landing_trajectories: Array
    var edge: FallFromWallEdge
    
    for jump_position in jump_positions:
        landing_trajectories = FallMovementUtils.find_landing_trajectories(collision_params, \
                surfaces_in_fall_range_set, jump_position, velocity_start)
        
        for calc_results in landing_trajectories:
            edge = FallFromWallEdge.new(jump_position, \
                    calc_results.overall_calc_params.destination_position, calc_results)
            edges_result.push_back(edge)
            
            # FIXME: ---------- Remove?
            if Utils.IN_DEV_MODE:
                MovementInstructionsUtils.test_instructions( \
                        edge.instructions, calc_results.overall_calc_params, calc_results)
