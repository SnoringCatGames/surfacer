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
    
    var top_jump_position := MovementUtils.create_position_offset_from_target_point( \
            origin_top_point, origin_surface, movement_params.collider_half_width_height)
    var bottom_jump_position := MovementUtils.create_position_offset_from_target_point( \
            origin_bottom_point, origin_surface, movement_params.collider_half_width_height)
    var jump_positions := [top_jump_position, bottom_jump_position]
    
    var landing_trajectories: Array
    var land_position: PositionAlongSurface
    var instructions: MovementInstructions
    var edge: FallFromWallEdge
    
    # TODO: When iterating over the second jump-off point, skip any destination surface that we've
    #       already found an edge to.
    
    for jump_position in jump_positions:
        landing_trajectories = FallMovementUtils.find_landing_trajectories(collision_params, \
                surfaces_in_fall_range_set, jump_position, velocity_start)
        
        for calc_results in landing_trajectories:
            land_position = calc_results.overall_calc_params.destination_position
            instructions = _calculate_instructions(jump_position, land_position, calc_results)
            edge = FallFromWallEdge.new( \
                    jump_position, land_position, movement_params, instructions)
            edges_result.push_back(edge)

static func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface, calc_results: MovementCalcResults) -> MovementInstructions:
    assert(start.surface.side == SurfaceSide.LEFT_WALL || \
            start.surface.side == SurfaceSide.RIGHT_WALL)
    
    # Calculate the fall-trajectory instructions.
    var instructions := \
            MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
                    calc_results, false, end.surface.side)
    
    # Calculate the wall-release instructions.
    var sideways_input_key := \
            "move_right" if start.surface.side == SurfaceSide.LEFT_WALL else "move_left"
    var outward_press := MovementInstruction.new(sideways_input_key, 0.0, true)
    var outward_release := MovementInstruction.new(sideways_input_key, 0.001, false)
    instructions.instructions.push_front(outward_release)
    instructions.instructions.push_front(outward_press)
    
    return instructions
