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

func get_all_inter_surface_edges_from_surface( \
        collision_params: CollisionCalcParams, \
        edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    Utils.error("abstract EdgeMovementCalculator.get_all_inter_surface_edges_from_surface is not implemented")

func calculate_edge( \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: PositionAlongSurface, \
        velocity_start := Vector2.INF, \
        in_debug_mode := false) -> Edge:
    Utils.error("abstract EdgeMovementCalculator.calculate_edge is not implemented")
    return null

# Sub-classes that implement optimize_edge_jump_position_for_path will need to implement this as
# well.
func get_velocity_starts( \
        movement_params: MovementParams, \
        jump_position: PositionAlongSurface) -> Array:
    Utils.error("abstract EdgeMovementCalculator.get_velocity_starts is not implemented")
    return []

func optimize_edge_jump_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        previous_velocity_end_x: float, \
        previous_edge: IntraSurfaceEdge, \
        edge: Edge, \
        in_debug_mode: bool) -> void:
    # Do nothing by default. Sub-classes implement this as needed.
    pass

func optimize_edge_land_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        edge: Edge, \
        next_edge: IntraSurfaceEdge, \
        in_debug_mode: bool) -> void:
    # Do nothing by default. Sub-classes implement this as needed.
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
        var mid_point_matching_edge_movement := Vector2.INF
        match surface.side:
            SurfaceSide.FLOOR:
                if surface_center.y < other_surface_center.y:
                    # Source surface is above other surface.
                    
                    # closest_point_on_source must be one of the ends of the source surface.
                    closest_point_on_surface = surface_last_point if \
                            surface_center.x < other_surface_center.x else \
                            surface_first_point
                    
                    mid_point_matching_edge_movement = Vector2.INF
                else:
                    # Source surface is below other surface.
                    
                    var closest_point_on_other_surface := Vector2.INF
                    var goal_x_on_surface: float = INF
                    var should_try_to_move_around_left_side_of_target: bool
                    
                    match other_surface_side:
                        SurfaceSide.FLOOR:
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
                            
                        SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
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
                            
                        SurfaceSide.CEILING:
                            # We can use any point along the other surface.
                            closest_point_on_surface = \
                                    Geometry.get_closest_point_on_polyline_to_polyline( \
                                            surface.vertices, \
                                            other_surface_vertices)
                            mid_point_matching_edge_movement = Vector2.INF
                        
                        _:
                            Utils.error()
                    
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
                        mid_point_matching_edge_movement = Geometry.project_point_onto_surface( \
                                Vector2(goal_x_on_surface, INF), \
                                surface)
                
            SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
                var gravity_for_inter_edge_distance_calc: float = INF
                
                match other_surface_side:
                    SurfaceSide.FLOOR:
                        if surface.side == SurfaceSide.LEFT_WALL and \
                                other_surface_bounding_box.end.x <= surface_center.x:
                            # The other surface is behind the source surface, so we assume we'll
                            # need to go around the top side of this source surface wall.
                            closest_point_on_surface = surface_first_point
                            mid_point_matching_edge_movement = Vector2.INF
                            gravity_for_inter_edge_distance_calc = INF
                            
                        elif surface.side == SurfaceSide.RIGHT_WALL and \
                                other_surface_bounding_box.position.x >= surface_center.x:
                            # The other surface is behind the source surface, so we assume we'll
                            # need to go around the top side of this source surface wall.
                            closest_point_on_surface = surface_last_point
                            mid_point_matching_edge_movement = Vector2.INF
                            gravity_for_inter_edge_distance_calc = INF
                            
                        else:
                            # The other surface, at least partially, is in front of the source
                            # surface wall.
                            
                            closest_point_on_surface = \
                                    Geometry.get_closest_point_on_polyline_to_polyline( \
                                            surface.vertices, \
                                            other_surface_vertices)
                            gravity_for_inter_edge_distance_calc = \
                                    movement_params.gravity_fast_fall
                        
                    SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
                        if (surface.side == SurfaceSide.LEFT_WALL and \
                                other_surface_side == SurfaceSide.RIGHT_WALL and \
                                surface_center.x < other_surface_center.x) or \
                                (surface.side == SurfaceSide.RIGHT_WALL and \
                                    other_surface_side == SurfaceSide.LEFT_WALL and \
                                    surface_center.x > other_surface_center.x):
                            # The surfaces are facing each other.
                            closest_point_on_surface = \
                                    Geometry.get_closest_point_on_polyline_to_polyline( \
                                            surface.vertices, \
                                            other_surface_vertices)
                        else:
                            # The surfaces aren't facing each other, so we assume we'll need to
                            # go around the top of at least one of them.
                            
                            var surface_top: float
                            if surface.side != other_surface_side:
                                # We need to go around the tops of both surfaces.
                                surface_top = min(surface.bounding_box.position.y, \
                                        other_surface_bounding_box.position.y)
                                
                            elif (surface.side == SurfaceSide.LEFT_WALL and \
                                    surface_center.x < other_surface_center.x) or \
                                    (surface.side == SurfaceSide.RIGHT_WALL and \
                                    surface_center.x > other_surface_center.x):
                                # We need to go around the top of the other surface.
                                surface_top = other_surface_bounding_box.position.y
                                
                            else:
                                # We need to go around the top of the source surface.
                                surface_top = surface.bounding_box.position.y
                            
                            closest_point_on_surface = Geometry.project_point_onto_surface( \
                                    Vector2(INF, surface_top), \
                                    surface)
                        
                        gravity_for_inter_edge_distance_calc = movement_params.gravity_fast_fall
                        
                    SurfaceSide.CEILING:
                        if surface.side == SurfaceSide.LEFT_WALL and \
                                other_surface_bounding_box.end.x <= surface_center.x:
                            # The other surface is behind the source surface, so we assume we'll
                            # need to go around the top side of this source surface wall.
                            closest_point_on_surface = surface_first_point
                            mid_point_matching_edge_movement = Vector2.INF
                            gravity_for_inter_edge_distance_calc = INF
                            
                        elif surface.side == SurfaceSide.RIGHT_WALL and \
                                other_surface_bounding_box.end.x >= surface_center.x:
                            # The other surface is behind the source surface, so we assume we'll
                            # need to go around the top side of this source surface wall.
                            closest_point_on_surface = surface_last_point
                            mid_point_matching_edge_movement = Vector2.INF
                            gravity_for_inter_edge_distance_calc = INF
                            
                        else:
                            # The other surface, at least partially, is in front of the source
                            # surface wall.
                            
                            closest_point_on_surface = \
                                    Geometry.get_closest_point_on_polyline_to_polyline( \
                                            surface.vertices, \
                                            other_surface_vertices)
                            gravity_for_inter_edge_distance_calc = movement_params.gravity_slow_rise
                        
                    _:
                        Utils.error()
                
                if gravity_for_inter_edge_distance_calc != INF:
                    # Calculate the point along the source surface that would correspond to
                    # falling/jumping to the closest land position on the other surface.
                    # 
                    # This makes a few simplifying assumptions:
                    # - Assumes only fast-fall gravity for the edge.
                    # - Assumes the edge starts with zero horizontal speed.
                    # - Assumes that the center of the source surface is at about the same
                    #   x-coordinate as the rest of the surface.
                    
                    var closest_point_on_other_surface: Vector2 = \
                            Geometry.get_closest_point_on_polyline_to_polyline( \
                                    other_surface_vertices, \
                                    surface.vertices)
                    var horizontal_distance := \
                            closest_point_on_other_surface.x - surface_center.x
                    var acceleration := \
                            movement_params.in_air_horizontal_acceleration if \
                            horizontal_distance >= 0.0 else \
                            -movement_params.in_air_horizontal_acceleration
                    var time_to_travel_horizontal_distance := \
                            MovementUtils.calculate_time_for_displacement( \
                                    horizontal_distance, \
                                    0.0, \
                                    acceleration, \
                                    movement_params.max_horizontal_speed_default)
                    # From a basic equation of motion:
                    #     s = s_0 + v_0*t + 1/2*a*t^2
                    # Algebra...:
                    #     (s - s_0) = v_0*t + 1/2*a*t^2
                    var vertical_distance := \
                            velocity_start_y * time_to_travel_horizontal_distance + \
                            0.5 * gravity_for_inter_edge_distance_calc * \
                            time_to_travel_horizontal_distance * \
                            time_to_travel_horizontal_distance
                    
                    mid_point_matching_edge_movement = \
                            Geometry.project_point_onto_surface( \
                                    Vector2(INF, closest_point_on_other_surface.y - \
                                            vertical_distance), \
                                    surface)
                
            SurfaceSide.CEILING:
                # TODO: Implement this case.
                closest_point_on_surface = \
                        Geometry.get_closest_point_on_polyline_to_polyline( \
                                surface.vertices, \
                                other_surface_vertices)
                
            _:
                Utils.error()
        
        # Only consider the horizontal-movement point if it is distinct.
        if movement_params.considers_mid_point_matching_edge_movement_for_jump_land_position and \
                mid_point_matching_edge_movement != Vector2.INF and \
                mid_point_matching_edge_movement != near_end and \
                mid_point_matching_edge_movement != far_end and \
                mid_point_matching_edge_movement != closest_point_on_surface:
            jump_position = MovementUtils.create_position_offset_from_target_point( \
                    mid_point_matching_edge_movement, \
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

static func optimize_edge_jump_position_for_path_helper( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        previous_velocity_end_x: float, \
        previous_edge: IntraSurfaceEdge, \
        edge: Edge, \
        in_debug_mode: bool, \
        edge_movement_calculator: EdgeMovementCalculator) -> void:
    # TODO: Refactor this to use a true binary search. Right now it is similar, but we never
    #       move backward once we find a working jump.
    var jump_ratios := [0.0, 0.5, 0.75, 0.875]
    
    var movement_params := collision_params.movement_params
    
    var previous_edge_displacement := previous_edge.end - previous_edge.start
    
    var is_horizontal_surface := \
            previous_edge.start_surface != null and \
            (previous_edge.start_surface.side == SurfaceSide.FLOOR or \
            previous_edge.start_surface.side == SurfaceSide.CEILING)
    
    if is_horizontal_surface:
        # Jumping from a floor or ceiling.
        
        var is_already_exceeding_max_speed_toward_displacement := \
                (previous_edge_displacement.x >= 0.0 and previous_velocity_end_x > \
                        movement_params.max_horizontal_speed_default) or \
                (previous_edge_displacement.x <= 0.0 and previous_velocity_end_x < \
                        -movement_params.max_horizontal_speed_default)
        
        var acceleration_x := movement_params.walk_acceleration if \
                previous_edge_displacement.x >= 0.0 else \
                -movement_params.walk_acceleration
        
        var jump_position: PositionAlongSurface
        var optimized_edge: Edge
        
        for i in range(jump_ratios.size()):
            if jump_ratios[i] == 0.0:
                jump_position = previous_edge.start_position_along_surface
            else:
                jump_position = MovementUtils.create_position_offset_from_target_point( \
                        Vector2(previous_edge.start.x + \
                                previous_edge_displacement.x * jump_ratios[i], 0.0), \
                        previous_edge.start_surface, \
                        movement_params.collider_half_width_height)
            
            # Calculate the start velocity to use according to the available ramp-up
            # distance and max speed.
            var velocity_start_x: float = MovementUtils.calculate_velocity_end_for_displacement( \
                    jump_position.target_point.x - previous_edge.start.x, \
                    previous_velocity_end_x, \
                    acceleration_x, \
                    movement_params.max_horizontal_speed_default)
            var velocity_start_y := movement_params.jump_boost
            var velocity_start = Vector2(velocity_start_x, velocity_start_y)
            
            optimized_edge = edge_movement_calculator.calculate_edge( \
                    collision_params, \
                    jump_position, \
                    edge.end_position_along_surface, \
                    velocity_start, \
                    in_debug_mode)
            
            if optimized_edge != null:
                optimized_edge.is_bespoke_for_path = true
                
                previous_edge = IntraSurfaceEdge.new( \
                        previous_edge.start_position_along_surface, \
                        jump_position, \
                        Vector2(previous_velocity_end_x, 0.0), \
                        movement_params)
                
                path.edges[edge_index - 1] = previous_edge
                path.edges[edge_index] = optimized_edge
                
                return
        
    else:
        # Jumping from a wall.
        
        var jump_position: PositionAlongSurface
        var velocity_start: Vector2
        var optimized_edge: Edge
        
        for i in range(jump_ratios.size()):
            if jump_ratios[i] == 0.0:
                jump_position = previous_edge.start_position_along_surface
            else:
                jump_position = MovementUtils.create_position_offset_from_target_point( \
                        Vector2(0.0, previous_edge.start.y + \
                                previous_edge_displacement.y * jump_ratios[i]), \
                        previous_edge.start_surface, \
                        movement_params.collider_half_width_height)
            
            velocity_start = edge_movement_calculator.get_velocity_starts( \
                    movement_params, \
                    jump_position)[0]
            
            optimized_edge = edge_movement_calculator.calculate_edge( \
                    collision_params, \
                    jump_position, \
                    edge.end_position_along_surface, \
                    velocity_start, \
                    in_debug_mode)
            
            if optimized_edge != null:
                optimized_edge.is_bespoke_for_path = true
                
                previous_edge = IntraSurfaceEdge.new( \
                        previous_edge.start_position_along_surface, \
                        jump_position, \
                        Vector2.ZERO, \
                        movement_params)
                
                path.edges[edge_index - 1] = previous_edge
                path.edges[edge_index] = optimized_edge
                
                return

static func optimize_edge_land_position_for_path_helper( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        edge: Edge, \
        next_edge: IntraSurfaceEdge, \
        in_debug_mode: bool, \
        edge_movement_calculator: EdgeMovementCalculator) -> void:
    # TODO: Refactor this to use a true binary search. Right now it is similar, but we never
    #       move backward once we find a working land.
    var land_ratios := [1.0, 0.5, 0.25, 0.125]
    
    var movement_params := collision_params.movement_params
    
    var next_edge_displacement := next_edge.end - next_edge.start
    
    var is_horizontal_surface := \
            next_edge.start_surface != null and \
            (next_edge.start_surface.side == SurfaceSide.FLOOR or \
            next_edge.start_surface.side == SurfaceSide.CEILING)
    
    if is_horizontal_surface:
        # Landing on a floor or ceiling.
        
        var land_position: PositionAlongSurface
        var calc_results: MovementCalcResults
        var optimized_edge: Edge
        
        for i in range(land_ratios.size()):
            if land_ratios[i] == 1.0:
                land_position = next_edge.end_position_along_surface
            else:
                land_position = MovementUtils.create_position_offset_from_target_point( \
                        Vector2(next_edge.start.x + \
                                next_edge_displacement.x * land_ratios[i], 0.0), \
                        next_edge.start_surface, \
                        movement_params.collider_half_width_height)
            
            optimized_edge = edge_movement_calculator.calculate_edge( \
                    collision_params, \
                    edge.start_position_along_surface, \
                    land_position, \
                    edge.velocity_start, \
                    in_debug_mode)
            
            if optimized_edge != null:
                optimized_edge.is_bespoke_for_path = true
                
                next_edge = IntraSurfaceEdge.new( \
                        land_position, \
                        next_edge.end_position_along_surface, \
                        optimized_edge.velocity_end, \
                        movement_params)
                
                path.edges[edge_index] = optimized_edge
                path.edges[edge_index + 1] = next_edge
                
                return
        
    else:
        # Landing on a wall.
        
        var land_position: PositionAlongSurface
        var calc_results: MovementCalcResults
        var optimized_edge: Edge
        
        for i in range(land_ratios.size()):
            if land_ratios[i] == 1.0:
                land_position = next_edge.end_position_along_surface
            else:
                land_position = MovementUtils.create_position_offset_from_target_point( \
                        Vector2(0.0, next_edge.start.y + \
                                next_edge_displacement.y * land_ratios[i]), \
                        next_edge.start_surface, \
                        movement_params.collider_half_width_height)
            
            optimized_edge = edge_movement_calculator.calculate_edge( \
                    collision_params, \
                    edge.start_position_along_surface, \
                    land_position, \
                    edge.velocity_start, \
                    in_debug_mode)
            
            if optimized_edge != null:
                optimized_edge.is_bespoke_for_path = true
                
                next_edge = IntraSurfaceEdge.new( \
                        land_position, \
                        next_edge.end_position_along_surface, \
                        Vector2.ZERO, \
                        movement_params)
                
                path.edges[edge_index] = optimized_edge
                path.edges[edge_index + 1] = edge
                
                return
