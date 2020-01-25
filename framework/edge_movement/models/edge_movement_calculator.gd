extends Reference
class_name EdgeMovementCalculator

var name: String

func _init(name: String) -> void:
    self.name = name

func get_can_traverse_from_surface(surface: Surface) -> bool:
    Utils.error("abstract EdgeMovementCalculator.get_can_traverse_from_surface is not implemented")
    return false

func get_all_edges_from_surface(collision_params: CollisionCalcParams, edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    Utils.error("abstract EdgeMovementCalculator.get_all_edges_from_surface is not implemented")
    pass

static func create_movement_calc_overall_params(
        collision_params: CollisionCalcParams, \
        origin_surface: Surface, origin_position: Vector2, \
        destination_surface: Surface, destination_position: Vector2, \
        can_hold_jump_button: bool, \
        velocity_start: Vector2, \
        returns_invalid_constraints: bool, \
        in_debug_mode: bool) -> MovementCalcOverallParams:
    var terminals := MovementConstraintUtils.create_terminal_constraints(origin_surface, \
            origin_position, destination_surface, destination_position, \
            collision_params.movement_params, can_hold_jump_button, velocity_start, \
            returns_invalid_constraints)
    if terminals.empty():
        return null
    
    var overall_calc_params := MovementCalcOverallParams.new(collision_params, terminals[0], \
            terminals[1], velocity_start, can_hold_jump_button)
    overall_calc_params.in_debug_mode = in_debug_mode
    
    return overall_calc_params

static func should_skip_edge_calculation(debug_state: Dictionary, origin_surface: Surface, \
        destination_surface: Surface, jump_position: PositionAlongSurface, \
        land_position: PositionAlongSurface, jump_positions: Array, land_positions: Array) -> bool:
    if debug_state.in_debug_mode and debug_state.has('limit_parsing') and \
            debug_state.limit_parsing.has('edge'):
        var debug_origin: Dictionary = debug_state.limit_parsing.edge.origin
        var debug_destination: Dictionary = debug_state.limit_parsing.edge.destination
        
        if origin_surface.side != debug_origin.surface_side or \
                destination_surface.side != debug_destination.surface_side or \
                origin_surface.first_point != debug_origin.surface_start_vertex or \
                origin_surface.last_point != debug_origin.surface_end_vertex or \
                destination_surface.first_point != debug_destination.surface_start_vertex or \
                destination_surface.last_point != debug_destination.surface_end_vertex:
            # Ignore anything except the origin and destination surface that we're
            # debugging.
            return true
        
        # Calculate the expected jumping position for debugging.
        var debug_jump_position: PositionAlongSurface
        match debug_origin.near_far_close_position:
            "near":
                debug_jump_position = jump_positions[0]
            "far":
                assert(jump_positions.size() > 1)
                debug_jump_position = jump_positions[1]
            "close":
                assert(jump_positions.size() > 2)
                debug_jump_position = jump_positions[2]
            _:
                Utils.error()
        
        # Calculate the expected landing position for debugging.
        var debug_land_position: PositionAlongSurface
        match debug_destination.near_far_close_position:
            "near":
                debug_land_position = land_positions[0]
            "far":
                assert(land_positions.size() > 1)
                debug_land_position = land_positions[1]
            "close":
                assert(land_positions.size() > 2)
                debug_land_position = land_positions[2]
            _:
                Utils.error()
        
        if jump_position != debug_jump_position or land_position != debug_land_position:
            # Ignore anything except the jump and land positions that we're debugging.
            return true
    
    return false
