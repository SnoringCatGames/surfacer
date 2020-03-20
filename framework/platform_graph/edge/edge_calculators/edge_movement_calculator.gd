extends Reference
class_name EdgeMovementCalculator

const MIN_LAND_ON_WALL_SPEED := 50.0

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
        origin_position: PositionAlongSurface, \
        destination_position: PositionAlongSurface, \
        can_hold_jump_button: bool, \
        velocity_start: Vector2, \
        returns_invalid_constraints: bool, \
        in_debug_mode: bool, \
        velocity_end_min_x := INF, \
        velocity_end_max_x := INF) -> MovementCalcOverallParams:
    # When landing on a wall, ensure that we end with velocity moving into the wall.
    if destination_position.surface != null:
        if destination_position.surface.side == SurfaceSide.LEFT_WALL:
            velocity_end_min_x = -collision_params.movement_params.max_horizontal_speed_default
            velocity_end_max_x = -MIN_LAND_ON_WALL_SPEED
        if destination_position.surface.side == SurfaceSide.RIGHT_WALL:
            velocity_end_min_x = MIN_LAND_ON_WALL_SPEED
            velocity_end_max_x = collision_params.movement_params.max_horizontal_speed_default
    
    var terminals := MovementConstraintUtils.create_terminal_constraints(origin_position, \
            destination_position, collision_params.movement_params, can_hold_jump_button, \
            velocity_start, velocity_end_min_x, velocity_end_max_x, returns_invalid_constraints)
    if terminals.empty():
        return null
    
    var overall_calc_params := MovementCalcOverallParams.new(collision_params, origin_position, \
            destination_position, terminals[0], terminals[1], velocity_start, can_hold_jump_button)
    overall_calc_params.in_debug_mode = in_debug_mode
    
    return overall_calc_params

static func should_skip_edge_calculation(debug_state: Dictionary, \
        jump_position: PositionAlongSurface, land_position: PositionAlongSurface) -> bool:
    if debug_state.in_debug_mode and debug_state.has("limit_parsing") and \
            debug_state.limit_parsing.has("edge"):
        
        if debug_state.limit_parsing.edge.has("origin"):
            if jump_position == null:
                # Ignore this if we expect to know the jump position, but don't.
                return true
            
            var debug_origin: Dictionary = debug_state.limit_parsing.edge.origin
            
            if (debug_origin.has("surface_side") and \
                    debug_origin.surface_side != jump_position.surface.side) or \
                    (debug_origin.has("surface_start_vertex") and \
                            debug_origin.surface_start_vertex != \
                                    jump_position.surface.first_point) or \
                    (debug_origin.has("surface_end_vertex") and \
                            debug_origin.surface_end_vertex != jump_position.surface.last_point):
                # Ignore anything except the origin surface that we're debugging.
                return true
            
            if debug_origin.has("position"):
                if !Geometry.are_points_equal_with_epsilon( \
                        jump_position.target_projection_onto_surface, debug_origin.position, 0.1):
                    # Ignore anything except the jump position that we're debugging.
                    return true
        
        if debug_state.limit_parsing.edge.has("destination"):
            if land_position == null:
                # Ignore this if we expect to know the land position, but don't.
                return true
            
            var debug_destination: Dictionary = debug_state.limit_parsing.edge.destination
            
            if (debug_destination.has("surface_side") and \
                    debug_destination.surface_side != land_position.surface.side) or \
                    (debug_destination.has("surface_start_vertex") and \
                            debug_destination.surface_start_vertex != \
                                    land_position.surface.first_point) or \
                    (debug_destination.has("surface_end_vertex") and \
                            debug_destination.surface_end_vertex != \
                                    land_position.surface.last_point):
                # Ignore anything except the destination surface that we're debugging.
                return true
            
            if debug_destination.has("position"):
                if !Geometry.are_points_equal_with_epsilon( \
                        land_position.target_projection_onto_surface, \
                        debug_destination.position, 0.1):
                    # Ignore anything except the land position that we're debugging.
                    return true
    
    return false
