extends Reference
class_name EdgeMovementCalculator

const MIN_LAND_ON_WALL_SPEED := 50.0
const EXTRA_JUMP_LAND_POSITION_MARGIN := 2.0
const MAX_VELOCITY_HORIZONTAL_OFFSET_SUBTRACT_PLAYER_WIDTH_RATIO := 0.6

var name: String

func _init(name: String) -> void:
    self.name = name

func get_can_traverse_from_surface(surface: Surface) -> bool:
    Utils.error("abstract EdgeMovementCalculator.get_can_traverse_from_surface is not implemented")
    return false

func get_all_edges_from_surface( \
        collision_params: CollisionCalcParams, \
        edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
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
    
    var terminals := MovementConstraintUtils.create_terminal_constraints( \
            origin_position, \
            destination_position, \
            collision_params.movement_params, \
            can_hold_jump_button, \
            velocity_start, \
            velocity_end_min_x, \
            velocity_end_max_x, \
            returns_invalid_constraints)
    if terminals.empty():
        return null
    
    var overall_calc_params := MovementCalcOverallParams.new( \
            collision_params, \
            origin_position, \
            destination_position, \
            terminals[0], \
            terminals[1], \
            velocity_start, \
            can_hold_jump_button)
    overall_calc_params.in_debug_mode = in_debug_mode
    
    return overall_calc_params

static func should_skip_edge_calculation( \
        debug_state: Dictionary, \
        jump_position: PositionAlongSurface, \
        land_position: PositionAlongSurface) -> bool:
    if debug_state.in_debug_mode and debug_state.has("limit_parsing") and \
            debug_state.limit_parsing.has("edge"):
        
        if debug_state.limit_parsing.edge.has("origin"):
            if jump_position == null:
                # Ignore this if we expect to know the jump position, but don't.
                return false
            
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
                return false
            
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

# Returns up to four points along the given surface for jumping-from or landing-to, considering
# the given vertices of another nearby surface.
# 
# -   The four possible points are:
#     -   The near end of the surface.
#     -   The far end of the surface.
#     -   The closest point along the surface (with an offset to account for player width).
#     -   The closest point along the surface with an offset that accounts for the potential
#         horizontal travel distance between the two surfaces.
# -   Points are only included if they are distinct.
# -   Points are returned in sorted order: closest, near, far.
static func get_all_jump_land_positions_for_surface( \
        movement_params: MovementParams, \
        surface: Surface, \
        other_surface_vertices: PoolVector2Array, \
        other_surface_bounding_box: Rect2, \
        other_surface_side: int, \
        velocity_start_y: float, \
        is_jump_off_surface: bool) -> Array:
    var surface_first_point := surface.first_point
    var surface_last_point := surface.last_point
    
    # Use a bounding-box heuristic to determine which end of the surfaces are likely to be
    # nearer and farther.
    var near_end := Vector2.INF
    var far_end := Vector2.INF
    if Geometry.distance_squared_from_point_to_rect( \
            surface_first_point, \
            other_surface_bounding_box) < \
            Geometry.distance_squared_from_point_to_rect( \
                    surface_last_point, \
                    other_surface_bounding_box):
        near_end = surface_first_point
        far_end = surface_last_point
    else:
        near_end = surface_last_point
        far_end = surface_first_point
    
    # Record the near-end point.
    var jump_position := MovementUtils.create_position_offset_from_target_point( \
            near_end, \
            surface, \
            movement_params.collider_half_width_height)
    var possible_jump_positions := [jump_position]
    
    # Only consider the far-end point if it is distinct.
    if surface.vertices.size() > 1:
        jump_position = MovementUtils.create_position_offset_from_target_point( \
                far_end, \
                surface, \
                movement_params.collider_half_width_height)
        possible_jump_positions.push_back(jump_position)
        
        var surface_center := surface.bounding_box.position + \
                (surface.bounding_box.end - surface.bounding_box.position) / 2.0
        var other_surface_center := other_surface_bounding_box.position + \
                (other_surface_bounding_box.end - other_surface_bounding_box.position) / 2.0
        var other_surface_first_point := other_surface_vertices[0]
        var other_surface_last_point := other_surface_vertices[other_surface_vertices.size() - 1]
        
        var player_width_horizontal_offset := movement_params.collider_half_width_height.x + \
                MovementCalcOverallParams.EDGE_MOVEMENT_ACTUAL_MARGIN + \
                EXTRA_JUMP_LAND_POSITION_MARGIN
        
        # Instead of choosing the exact closest point along the source surface to the other
        # surface, we may want to give the "closest" jump-off point an offset (corresponding to the
        # player's width) that should reduce overall movement.
        # 
        # As an example of when this offset is important, consider the case when we jump from floor
        # surface A to floor surface B, which lies exactly above A. In this case, the jump movement
        # must go around one edge of B or the other in order to land on the top-side of B. Ideally,
        # the jump position from A would already be outside the edge of B, so that we don't need to
        # first move horizontally outward and then back in. However, the exact "closest" point on A
        # to B will not be outside the edge of B.
        var closest_point_on_surface := Vector2.INF
        var mid_point_matching_horizontal_movement := Vector2.INF
        if surface.side == SurfaceSide.FLOOR:
            if surface_center.y < other_surface_center.y:
                # Source surface is above other surface.
                
                # closest_point_on_source must be one of the ends of the source surface.
                closest_point_on_surface = surface_last_point if \
                        surface_center.x < other_surface_center.x else \
                        surface_first_point
                
                mid_point_matching_horizontal_movement = Vector2.INF
            else:
                # Source surface is below other surface.
                
                var closest_point_on_other_surface := Vector2.INF
                var goal_x_on_surface: float = INF
                var should_try_to_move_around_left_side_of_target: bool
                
                if other_surface_side == SurfaceSide.FLOOR:
                    # Choose whichever other-surface end point is closer to the source center, and
                    # calculate a half-player-width offset from there.
                    should_try_to_move_around_left_side_of_target = \
                            abs(other_surface_first_point.x - surface_center.x) < \
                            abs(other_surface_last_point.x - surface_center.x)
                    
                    # Calculate the "closest" point on the source surface to our goal offset point.
                    if should_try_to_move_around_left_side_of_target:
                        closest_point_on_other_surface = other_surface_first_point
                        goal_x_on_surface = closest_point_on_other_surface.x - \
                                player_width_horizontal_offset
                    else:
                        closest_point_on_other_surface = other_surface_last_point
                        goal_x_on_surface = closest_point_on_other_surface.x + \
                                player_width_horizontal_offset
                    closest_point_on_surface = Geometry.project_point_onto_surface( \
                            Vector2(goal_x_on_surface, INF), \
                            surface)
                    
                elif other_surface_side == SurfaceSide.LEFT_WALL or \
                        other_surface_side == SurfaceSide.RIGHT_WALL:
                    should_try_to_move_around_left_side_of_target = \
                            other_surface_side == SurfaceSide.RIGHT_WALL
                    # Find the point along the other surface that's closest to the source surface,
                    # and calculate a half-player-width offset from there.
                    closest_point_on_other_surface = \
                            Geometry.get_closest_point_on_polyline_to_polyline( \
                                    other_surface_vertices, \
                                    surface.vertices)
                    goal_x_on_surface = closest_point_on_other_surface.x + \
                            (player_width_horizontal_offset if \
                            other_surface_side == SurfaceSide.LEFT_WALL else \
                            -player_width_horizontal_offset)
                    # Calculate the "closest" point on the source surface to our goal offset point.
                    closest_point_on_surface = Geometry.project_point_onto_surface( \
                            Vector2(goal_x_on_surface, INF), \
                            surface)
                    
                else: # other_surface_side == SurfaceSide.CEILING
                    # We can use any point along the other surface.
                    closest_point_on_surface = \
                            Geometry.get_closest_point_on_polyline_to_polyline( \
                                    surface.vertices, \
                                    other_surface_vertices)
                
                if other_surface_side != SurfaceSide.CEILING:
                    # Calculate the point along the source surface that would correspond to the
                    # closest land position on the other surface, while maintaining a max-speed
                    # horizontal velocity for the duration of the movement.
                    # 
                    # This makes a few simplifying assumptions:
                    # - Assumes only fast-fall gravity for the edge.
                    # - Assumes the edge starts with the max horizontal speed.
                    # - Assumes that the center of the surface is at the same height as the
                    #   resulting point along the surface that we are calculating.
                    
                    var displacement_y := closest_point_on_other_surface.y - surface_center.y
                    var fall_time_with_max_gravity := \
                            MovementUtils.calculate_time_for_displacement( \
                                    displacement_y if is_jump_off_surface else -displacement_y, \
                                    velocity_start_y, \
                                    movement_params.gravity_fast_fall, \
                                    movement_params.max_vertical_speed)
                    # (s - s_0) = v*t
                    var max_velocity_horizontal_offset := \
                            movement_params.max_horizontal_speed_default * \
                            fall_time_with_max_gravity
                    # This max velocity range could overshoot what's actually reachable, so we
                    # subtract a portion of the player's width to more likely end up with a usable
                    # position.
                    max_velocity_horizontal_offset -= \
                            player_width_horizontal_offset * \
                            MAX_VELOCITY_HORIZONTAL_OFFSET_SUBTRACT_PLAYER_WIDTH_RATIO
                    goal_x_on_surface += -max_velocity_horizontal_offset if \
                            should_try_to_move_around_left_side_of_target else \
                            max_velocity_horizontal_offset
                    mid_point_matching_horizontal_movement = Geometry.project_point_onto_surface( \
                            Vector2(goal_x_on_surface, INF), \
                            surface)
            
        elif surface.side == SurfaceSide.LEFT_WALL or \
                surface.side == SurfaceSide.RIGHT_WALL:
            # FIXME: -------------- LEFT OFF HERE
            # FIXME: -------------- REMOVE
            closest_point_on_surface = \
                    Geometry.get_closest_point_on_polyline_to_polyline( \
                            surface.vertices, \
                            other_surface_vertices)
            
        else: # surface.side == SurfaceSide.CEILING
            # FIXME: -------------- LEFT OFF HERE
            # FIXME: -------------- REMOVE
            closest_point_on_surface = \
                    Geometry.get_closest_point_on_polyline_to_polyline( \
                            surface.vertices, \
                            other_surface_vertices)
        
        # Only consider the horizontal-movement point if it is distinct.
        if movement_params.considers_mid_point_matching_horizontal_movement_for_jump_land_position and \
                mid_point_matching_horizontal_movement != Vector2.INF and \
                mid_point_matching_horizontal_movement != near_end and \
                mid_point_matching_horizontal_movement != far_end and \
                mid_point_matching_horizontal_movement != closest_point_on_surface:
            jump_position = MovementUtils.create_position_offset_from_target_point( \
                    mid_point_matching_horizontal_movement, \
                    surface, \
                    movement_params.collider_half_width_height)
            possible_jump_positions.push_front(jump_position)
        
        # Only consider the "closest" point if it is distinct.
        if movement_params.considers_closest_mid_point_for_jump_land_position and \
                closest_point_on_surface != Vector2.INF and \
                closest_point_on_surface != near_end and \
                closest_point_on_surface != far_end:
            jump_position = MovementUtils.create_position_offset_from_target_point( \
                    closest_point_on_surface, \
                    surface, \
                    movement_params.collider_half_width_height)
            possible_jump_positions.push_front(jump_position)
    
    return possible_jump_positions
