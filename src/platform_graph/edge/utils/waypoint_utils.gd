class_name WaypointUtils
extends Reference
# A collection of utility functions for calculating state related to Waypoints.


# TODO: Tweak this.
const MIN_MAX_VELOCITY_X_OFFSET := 0.01

const FAKE_REPLACEMENT_SEARCH_MAX_ITERATIONS := 6

# TODO: Replace the hard-coded usage of a max-speed ratio with a smarter
#       x-velocity.
const CALCULATE_TIME_TO_REACH_DESTINATION_FROM_NEW_WAYPOINT_V_X_MAX_SPEED_MULTIPLIER := \
        0.5


static func create_terminal_waypoints(
        edge_result_metadata: EdgeCalcResultMetadata,
        origin_position: PositionAlongSurface,
        destination_position: PositionAlongSurface,
        movement_params: MovementParameters,
        can_hold_jump_button: bool,
        velocity_start: Vector2,
        velocity_end_min_x: float,
        velocity_end_max_x: float,
        needs_extra_jump_duration: bool) -> Array:
    var origin_passing_vertically := \
            origin_position.surface.normal.x == 0 if \
            origin_position.surface != null \
            else true
    var destination_passing_vertically := \
            destination_position.surface.normal.x == 0 if \
            destination_position.surface != null \
            else true
    
    var origin := Waypoint.new(
            origin_position.surface,
            origin_position.target_point,
            origin_passing_vertically,
            false,
            false,
            null,
            null)
    var destination := Waypoint.new(
            destination_position.surface,
            destination_position.target_point,
            destination_passing_vertically,
            false,
            false,
            null,
            null)
    
    origin.is_origin = true
    origin.next_waypoint = destination
    destination.is_destination = true
    destination.previous_waypoint = origin
    destination.needs_extra_jump_duration = needs_extra_jump_duration
    
    if !is_inf(velocity_end_min_x) or !is_inf(velocity_end_max_x):
        destination.min_velocity_x = velocity_end_min_x
        destination.max_velocity_x = velocity_end_max_x
    
    update_waypoint(
            origin,
            origin,
            movement_params,
            velocity_start,
            can_hold_jump_button,
            null,
            Vector2.INF)
    update_waypoint(
            destination,
            origin,
            movement_params,
            velocity_start,
            can_hold_jump_button,
            null,
            Vector2.INF)
    assert(!origin.is_fake and !destination.is_fake)
    
    if origin.is_valid and destination.is_valid:
        return [origin, destination]
    else:
        edge_result_metadata.edge_calc_result_type = \
                EdgeCalcResultType.WAYPOINT_INVALID
        edge_result_metadata.waypoint_validity = \
                destination.validity if \
                !destination.is_valid else \
                origin.validity
        return []


# Assuming movement would otherwise collide with the given surface, this
# calculates positions along the edges of the surface that the movement could
# pass through in order to go around the surface.
static func calculate_waypoints_around_surface(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        movement_params: MovementParameters,
        vertical_step: VerticalEdgeStep,
        previous_waypoint: Waypoint,
        next_waypoint: Waypoint,
        origin_waypoint: Waypoint,
        destination_waypoint: Waypoint,
        colliding_surface: Surface,
        waypoint_offset: Vector2) -> Array:
    Sc.profiler.start(
            "calculate_waypoints_around_surface",
            collision_params.thread_id)
    
    var passing_vertically: bool
    var should_stay_on_min_side_ccw: bool
    var should_stay_on_min_side_cw: bool
    var position_ccw := Vector2.INF
    var position_cw := Vector2.INF
    
    # Get references to the the furthest collinear transitive-neighbor surfaces.
    var colliding_collinear_cw := colliding_surface
    while colliding_collinear_cw.clockwise_collinear_neighbor != null:
        colliding_collinear_cw = \
                colliding_collinear_cw.clockwise_collinear_neighbor
    var colliding_collinear_ccw := colliding_surface
    while colliding_collinear_ccw.clockwise_collinear_neighbor != null:
        colliding_collinear_ccw = \
                colliding_collinear_ccw.clockwise_collinear_neighbor
    
    # Calculate the positions of each waypoint.
    match colliding_surface.side:
        SurfaceSide.FLOOR:
            passing_vertically = true
            should_stay_on_min_side_ccw = true
            should_stay_on_min_side_cw = false
            # Left end (counter-clockwise end).
            position_ccw = colliding_collinear_ccw.first_point + \
                    Vector2(-waypoint_offset.x, -waypoint_offset.y)
            # Right end (clockwise end).
            position_cw = colliding_collinear_cw.last_point + \
                    Vector2(waypoint_offset.x, -waypoint_offset.y)
        SurfaceSide.CEILING:
            passing_vertically = true
            should_stay_on_min_side_ccw = false
            should_stay_on_min_side_cw = true
            # Right end (counter-clockwise end).
            position_ccw = colliding_collinear_ccw.first_point + \
                    Vector2(waypoint_offset.x, waypoint_offset.y)
            # Left end (clockwise end).
            position_cw = colliding_collinear_cw.last_point + \
                    Vector2(-waypoint_offset.x, waypoint_offset.y)
        SurfaceSide.LEFT_WALL:
            passing_vertically = false
            should_stay_on_min_side_ccw = true
            should_stay_on_min_side_cw = false
            # Top end (counter-clockwise end).
            position_ccw = colliding_collinear_ccw.first_point + \
                    Vector2(waypoint_offset.x, -waypoint_offset.y)
            # Bottom end (clockwise end).
            position_cw = colliding_collinear_cw.last_point + \
                    Vector2(waypoint_offset.x, waypoint_offset.y)
        SurfaceSide.RIGHT_WALL:
            passing_vertically = false
            should_stay_on_min_side_ccw = false
            should_stay_on_min_side_cw = true
            # Bottom end (counter-clockwise end).
            position_ccw = colliding_collinear_ccw.first_point + \
                    Vector2(-waypoint_offset.x, waypoint_offset.y)
            # Top end (clockwise end).
            position_cw = colliding_collinear_cw.last_point + \
                    Vector2(-waypoint_offset.x, -waypoint_offset.y)
    
    var should_skip_ccw := false
    var should_skip_cw := false
    
    # We ignore waypoints that would correspond to moving back the way we came.
    if previous_waypoint.surface != null and \
            previous_waypoint.surface == \
            colliding_collinear_ccw.counter_clockwise_convex_neighbor:
        should_skip_ccw = true
    if previous_waypoint.surface != null and \
            previous_waypoint.surface == \
            colliding_collinear_cw.clockwise_convex_neighbor:
        should_skip_cw = true
    
    # We ignore waypoints that are redundant with the constraint we were
    # already using with the previous step attempt.
    # 
    # -   That is, the calculated waypoint is at the same position as the next
    #     waypoint.
    # -   This should never happen!
    if position_ccw == next_waypoint.position:
        should_skip_ccw = true
        Sc.logger.error(
                "Calculated a redundant waypoint (the calculated waypoint " +
                "is at the same position as the next waypoint).")
    if position_cw == next_waypoint.position:
        should_skip_cw = true
        Sc.logger.error(
                "Calculated a redundant waypoint (the calculated waypoint " +
                "is at the same position as the next waypoint).")
    
    var waypoint_a_original: Waypoint
    var waypoint_a_final: Waypoint
    var waypoint_b_original: Waypoint
    var waypoint_b_final: Waypoint
    
    if !should_skip_ccw:
        waypoint_a_original = Waypoint.new(
                colliding_collinear_ccw,
                position_ccw,
                passing_vertically,
                should_stay_on_min_side_ccw,
                true,
                previous_waypoint,
                next_waypoint)
        # Calculate and record state for the waypoint.
        update_waypoint(
                waypoint_a_original,
                origin_waypoint,
                movement_params,
                vertical_step.velocity_step_start,
                vertical_step.can_hold_jump_button,
                vertical_step,
                Vector2.INF)
        # If the waypoint is fake, then replace it with its real neighbor, and
        # re-calculate state for the neighbor.
        if waypoint_a_original.is_fake:
            waypoint_a_final = _calculate_replacement_for_fake_waypoint(
                    waypoint_a_original,
                    waypoint_offset)
            if waypoint_a_final != null:
                update_waypoint(
                        waypoint_a_final,
                        origin_waypoint,
                        movement_params,
                        vertical_step.velocity_step_start,
                        vertical_step.can_hold_jump_button,
                        vertical_step,
                        Vector2.INF)
        else:
            waypoint_a_final = waypoint_a_original
    
    if !should_skip_cw:
        waypoint_b_original = Waypoint.new(
                colliding_collinear_cw,
                position_cw,
                passing_vertically,
                should_stay_on_min_side_cw,
                true,
                previous_waypoint,
                next_waypoint)
        # Calculate and record state for the waypoint.
        update_waypoint(
                waypoint_b_original,
                origin_waypoint,
                movement_params,
                vertical_step.velocity_step_start,
                vertical_step.can_hold_jump_button,
                vertical_step,
                Vector2.INF)
        # If the waypoint is fake, then replace it with its real neighbor, and
        # re-calculate state for the neighbor.
        if waypoint_b_original.is_fake:
            waypoint_b_final = _calculate_replacement_for_fake_waypoint(
                    waypoint_b_original,
                    waypoint_offset)
            if waypoint_b_final != null:
                update_waypoint(
                        waypoint_b_final,
                        origin_waypoint,
                        movement_params,
                        vertical_step.velocity_step_start,
                        vertical_step.can_hold_jump_button,
                        vertical_step,
                        Vector2.INF)
        else:
            waypoint_b_final = waypoint_b_original
    
    var waypoints: Array
    if !should_skip_ccw and \
            !should_skip_cw and \
            waypoint_a_final != null and \
            waypoint_b_final != null:
        # Return the waypoints in sorted order according to which is more
        # likely to produce successful movement.
        if _compare_waypoints_by_more_likely_to_be_valid(
                waypoint_a_original,
                waypoint_b_original,
                waypoint_a_final,
                waypoint_b_final,
                origin_waypoint,
                destination_waypoint):
            waypoints = [waypoint_a_final, waypoint_b_final]
        else:
            waypoints = [waypoint_b_final, waypoint_a_final]
    elif !should_skip_ccw and waypoint_a_final != null:
        waypoints = [waypoint_a_final]
    elif !should_skip_cw and waypoint_b_final != null:
        waypoints = [waypoint_b_final]
    else:
        if should_skip_ccw and should_skip_cw:
            Sc.logger.error("WaypointUtils.calculate_waypoints_around_surface")
        waypoints = []
    
    _calculate_protrusion_waypoint(
            waypoints,
            edge_result_metadata,
            collision_params,
            movement_params,
            vertical_step,
            previous_waypoint,
            next_waypoint,
            origin_waypoint,
            destination_waypoint,
            colliding_surface,
            waypoint_offset)
    
    Sc.profiler.stop_with_optional_metadata(
            "calculate_waypoints_around_surface",
            collision_params.thread_id,
            edge_result_metadata)
    return waypoints


static func _calculate_protrusion_waypoint(
        result: Array,
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        movement_params: MovementParameters,
        vertical_step: VerticalEdgeStep,
        previous_waypoint: Waypoint,
        next_waypoint: Waypoint,
        origin_waypoint: Waypoint,
        destination_waypoint: Waypoint,
        colliding_surface: Surface,
        waypoint_offset: Vector2) -> void:
    if colliding_surface.is_single_vertex:
        return
    
    # Get references to the the furthest collinear transitive-neighbor surfaces.
    var colliding_collinear_cw := colliding_surface
    while colliding_collinear_cw.clockwise_collinear_neighbor != null:
        colliding_collinear_cw = \
                colliding_collinear_cw.clockwise_collinear_neighbor
    var colliding_collinear_ccw := colliding_surface
    while colliding_collinear_ccw.clockwise_collinear_neighbor != null:
        colliding_collinear_ccw = \
                colliding_collinear_ccw.clockwise_collinear_neighbor
    
    # Calculate the combined collinear-neighbor bounding-box.
    var current_surface := colliding_collinear_ccw
    var collinear_neighbors_bb := current_surface.bounding_box
    while current_surface.clockwise_collinear_neighbor != null:
        current_surface = current_surface.clockwise_collinear_neighbor
        collinear_neighbors_bb.merge(current_surface.bounding_box)
    
    var protrusion_position := Vector2.INF
    var protrusion_surface: Surface
    var passing_protrusion_vertically: bool
    var should_stay_on_protrusion_min_side: bool
    
    match colliding_surface.side:
        SurfaceSide.FLOOR:
            var min_y := collinear_neighbors_bb.position.y
            var does_middle_vertex_protrude := \
                    colliding_collinear_ccw.first_point.y > min_y + 0.1 and \
                    colliding_collinear_cw.last_point.y > min_y + 0.1
            if does_middle_vertex_protrude:
                var protruding_vertex := Vector2.INF
                current_surface = colliding_collinear_ccw
                while current_surface.clockwise_collinear_neighbor != null:
                    current_surface = \
                            current_surface.clockwise_collinear_neighbor
                    for vertex in current_surface.vertices:
                        if vertex.y < protruding_vertex.y:
                            protruding_vertex = vertex
                            protrusion_surface = current_surface
                protrusion_position = \
                        protruding_vertex + \
                        Vector2(0.0, -waypoint_offset.y)
                passing_protrusion_vertically = false
                should_stay_on_protrusion_min_side = true
            
        SurfaceSide.LEFT_WALL:
            var max_x := collinear_neighbors_bb.end.x
            var does_middle_vertex_protrude := \
                    colliding_collinear_ccw.first_point.x < max_x - 0.1 and \
                    colliding_collinear_cw.last_point.x < max_x - 0.1
            if does_middle_vertex_protrude:
                var protruding_vertex := -Vector2.INF
                current_surface = colliding_collinear_ccw
                while current_surface.clockwise_collinear_neighbor != null:
                    current_surface = \
                            current_surface.clockwise_collinear_neighbor
                    for vertex in current_surface.vertices:
                        if vertex.x > protruding_vertex.x:
                            protruding_vertex = vertex
                            protrusion_surface = current_surface
                protrusion_position = \
                        protruding_vertex + \
                        Vector2(waypoint_offset.x, 0.0)
                passing_protrusion_vertically = true
                should_stay_on_protrusion_min_side = false
            
        SurfaceSide.RIGHT_WALL:
            var min_x := collinear_neighbors_bb.position.x
            var does_middle_vertex_protrude := \
                    colliding_collinear_ccw.first_point.x > min_x + 0.1 and \
                    colliding_collinear_cw.last_point.x > min_x + 0.1
            if does_middle_vertex_protrude:
                var protruding_vertex := Vector2.INF
                current_surface = colliding_collinear_ccw
                while current_surface.clockwise_collinear_neighbor != null:
                    current_surface = \
                            current_surface.clockwise_collinear_neighbor
                    for vertex in current_surface.vertices:
                        if vertex.x < protruding_vertex.x:
                            protruding_vertex = vertex
                            protrusion_surface = current_surface
                protrusion_position = \
                        protruding_vertex + \
                        Vector2(-waypoint_offset.x, 0.0)
                passing_protrusion_vertically = true
                should_stay_on_protrusion_min_side = true
            
        SurfaceSide.CEILING:
            var max_y := collinear_neighbors_bb.end.y
            var does_middle_vertex_protrude := \
                    colliding_collinear_ccw.first_point.y < max_y - 0.1 and \
                    colliding_collinear_cw.last_point.y < max_y - 0.1
            if does_middle_vertex_protrude:
                var protruding_vertex := -Vector2.INF
                current_surface = colliding_collinear_ccw
                while current_surface.clockwise_collinear_neighbor != null:
                    current_surface = \
                            current_surface.clockwise_collinear_neighbor
                    for vertex in current_surface.vertices:
                        if vertex.y > protruding_vertex.y:
                            protruding_vertex = vertex
                            protrusion_surface = current_surface
                protrusion_position = \
                        protruding_vertex + \
                        Vector2(0.0, waypoint_offset.y)
                passing_protrusion_vertically = false
                should_stay_on_protrusion_min_side = false
            
        _:
            Sc.logger.error("WaypointUtils._calculate_protrusion_waypoint")
    
    if !Sc.geometry.is_point_partial_inf(protrusion_position):
        var protrusion_waypoint := Waypoint.new(
                protrusion_surface,
                protrusion_position,
                passing_protrusion_vertically,
                should_stay_on_protrusion_min_side,
                false,
                previous_waypoint,
                next_waypoint)
        # Calculate and record state for the waypoint.
        update_waypoint(
                protrusion_waypoint,
                origin_waypoint,
                movement_params,
                vertical_step.velocity_step_start,
                vertical_step.can_hold_jump_button,
                vertical_step,
                Vector2.INF)
        
        # Include the result, in sorted order.
        if result.size() >= 1 and \
                !result[0].is_valid:
            result.insert(0, protrusion_waypoint)
        elif result.size() == 2 and \
                !result[1].is_valid:
            result.insert(1, protrusion_waypoint)
        else:
            result.append(protrusion_waypoint)


# Use some basic heuristics to sort the waypoints. We try to attempt
# calculations for the waypoint that's most likely to be successful first.
static func _compare_waypoints_by_more_likely_to_be_valid(
        a_original: Waypoint,
        b_original: Waypoint,
        a_final: Waypoint,
        b_final: Waypoint,
        origin: Waypoint,
        destination: Waypoint) -> bool:
    if a_final.is_valid != b_final.is_valid:
        # Sort waypoints according to whether they're valid.
        return a_final.is_valid
    else:
        # Sort waypoints according to position.
        
        var colliding_surface := a_original.surface
        
        if colliding_surface.side == SurfaceSide.FLOOR:
            # When moving around a floor, prefer whichever waypoint is closer
            # to the destination.
            # 
            # Movement is more likely to be indirect and needless zig-zag
            # around the surface when we consider the side further from the
            # destination.
            return a_original.position.distance_squared_to(
                            destination.position) <= \
                    b_original.position.distance_squared_to(
                            destination.position)
        elif colliding_surface.side == SurfaceSide.CEILING:
            # When moving around a ceiling, prefer whichever waypoint is closer
            # to the origin.
            # 
            # Movement is more likely to be direct and successful if we go over
            # the region, rather than under and around, which is what we
            # attempt when we consider the far end of a ceiling surface.
            return a_original.position.distance_squared_to(
                            origin.position) <= \
                    b_original.position.distance_squared_to(origin.position)
        else:
            # When moving around walls, prefer whichever waypoint is higher.
            # 
            # The reasoning here is that the waypoint around the bottom edge of
            # a wall will usually require movement to use a lower jump height,
            # which would then invalidate the rest of the movement to the
            # destination.
            return a_original.position.y <= b_original.position.y


# Calculates and records various state on the given waypoint.
# 
# In particular, these waypoint properties are updated:
# -   is_fake
# -   is_valid
# -   horizontal_movement_sign
# -   horizontal_movement_sign_from_displacement
# -   time_passing_through
# -   min_velocity_x
# -   max_velocity_x
# 
# These calculations take into account state from previous and upcoming
# neighbor waypoints as well as various other parameters.
# 
# Returns false if the waypoint cannot satisfy the given parameters.
static func update_waypoint(
        waypoint: Waypoint,
        origin_waypoint: Waypoint,
        movement_params: MovementParameters,
        velocity_start_origin: Vector2,
        can_hold_jump_button_at_origin: bool,
        vertical_step: VerticalEdgeStep,
        additional_high_waypoint_position: Vector2) -> void:
    # Previous waypoint, next waypoint, and vertical_step should be provided
    # when updating intermediate waypoints.
    assert(waypoint.previous_waypoint != null or \
            waypoint.is_origin)
    assert(waypoint.next_waypoint != null or \
            waypoint.is_destination)
    assert(vertical_step != null or \
            waypoint.is_destination or \
            waypoint.is_origin)
    
    # additional_high_waypoint_position should only ever be provided for the
    # destination, and then only when we're doing backtracking for a new
    # jump-height.
    assert(additional_high_waypoint_position == Vector2.INF or \
            waypoint.is_destination)
    assert(vertical_step != null or \
            additional_high_waypoint_position == Vector2.INF)
    
    _assign_horizontal_movement_sign(
            waypoint,
            velocity_start_origin)
    
    var is_a_horizontal_surface := \
            waypoint.surface != null and \
            waypoint.surface.normal.x == 0
    var is_a_fake_waypoint := \
            !waypoint.is_origin and \
            !waypoint.is_destination and \
            waypoint.is_at_end_of_surface and \
            waypoint.surface != null and \
            waypoint.horizontal_movement_sign != \
                    waypoint.horizontal_movement_sign_from_displacement and \
            is_a_horizontal_surface
    
    if is_a_fake_waypoint:
        # This waypoint should be skipped, and movement should proceed directly
        # to the next one (but we still need to keep this waypoint around long
        # enough to calculate what that next waypoint is).
        waypoint.is_fake = true
        waypoint.horizontal_movement_sign = \
                waypoint.horizontal_movement_sign_from_displacement
        waypoint.validity = WaypointValidity.FAKE
    else:
        waypoint.validity = _update_waypoint_velocity_and_time(
                waypoint,
                origin_waypoint,
                movement_params,
                velocity_start_origin,
                can_hold_jump_button_at_origin,
                vertical_step,
                additional_high_waypoint_position)


# Calculates and records various state on the given waypoint.
# 
# In particular, these waypoint properties are updated:
# -   time_passing_through
# -   min_velocity_x
# -   max_velocity_x
# 
# These calculations take into account state from neighbor waypoints as well as
# various other parameters.
# 
# Returns WaypointValidity.
static func _update_waypoint_velocity_and_time(
        waypoint: Waypoint,
        origin_waypoint: Waypoint,
        movement_params: MovementParameters,
        velocity_start_origin: Vector2,
        can_hold_jump_button_at_origin: bool,
        vertical_step: VerticalEdgeStep,
        additional_high_waypoint_position: Vector2) -> int:
    # TODO: Account for max y velocity when calculating any parabolic motion.
    
    var time_passing_through: float
    var min_velocity_x: float
    var max_velocity_x: float
    var actual_velocity_x: float
    
    # Calculate the time that the movement would pass through the waypoint, as
    # well as the min and max x-velocity when passing through the waypoint.
    if waypoint.is_origin:
        time_passing_through = 0.0
        min_velocity_x = velocity_start_origin.x
        max_velocity_x = velocity_start_origin.x
        actual_velocity_x = velocity_start_origin.x
    else:
        var displacement := \
                waypoint.next_waypoint.position - waypoint.position if \
                waypoint.next_waypoint != null else \
                waypoint.position - waypoint.previous_waypoint.position
        
        # Check whether the vertical displacement is possible.
        if displacement.y < -movement_params.max_upward_jump_distance:
            # We can't reach the next waypoint from this waypoint.
            return WaypointValidity.TOO_HIGH
        
        if waypoint.is_destination:
            # We consider different parameters if we are starting a new
            # movement calculation vs backtracking to consider a new jump
            # height.
            var waypoint_position_to_calculate_jump_release_time_for: Vector2
            if additional_high_waypoint_position == Vector2.INF:
                # We are starting a new movement calculation (not backtracking
                # to consider a new jump height).
                waypoint_position_to_calculate_jump_release_time_for = \
                        waypoint.position
            else:
                # We are backtracking to consider a new jump height.
                waypoint_position_to_calculate_jump_release_time_for = \
                        additional_high_waypoint_position
            
            # TODO: I should probably refactor these two calls, so we're doing
            #       fewer redundant calculations here.
            
            var displacement_from_origin_to_waypoint := \
                    waypoint_position_to_calculate_jump_release_time_for - \
                    origin_waypoint.position
            
            # If we already know the required time for reaching the
            # destination, and we aren't performing a new backtracking step,
            # then re-use the previously calculated time. The previous value
            # encompasses more information that we may need to preserve, such
            # as whether we already did some backtracking.
            var time_to_pass_through_waypoint_ignoring_others: float
            if vertical_step != null and \
                    additional_high_waypoint_position == Vector2.INF:
                time_to_pass_through_waypoint_ignoring_others = \
                        vertical_step.time_step_end
            else:
                var must_reach_destination_on_fall := \
                        additional_high_waypoint_position != Vector2.INF or \
                        waypoint.side == SurfaceSide.FLOOR
                var must_reach_destination_on_rise := \
                        waypoint.side == SurfaceSide.CEILING
                time_to_pass_through_waypoint_ignoring_others = \
                        VerticalMovementUtils \
                                .calculate_time_to_jump_to_waypoint(
                                        movement_params,
                                        displacement_from_origin_to_waypoint,
                                        velocity_start_origin,
                                        can_hold_jump_button_at_origin,
                                        must_reach_destination_on_fall,
                                        must_reach_destination_on_rise)
                if is_inf(time_to_pass_through_waypoint_ignoring_others):
                    # We can't reach this waypoint.
                    return WaypointValidity.OUT_OF_REACH_FROM_ORIGIN
                
                # TODO: This was added because we saw an instance of
                #       displacement_from_origin_to_waypoint.y == 0, which led
                #       to to the time being zero. Maybe this isn't the right
                #       fix?
                if time_to_pass_through_waypoint_ignoring_others == 0.0:
                    time_to_pass_through_waypoint_ignoring_others += 0.0001
                
                assert(time_to_pass_through_waypoint_ignoring_others > 0.0)
            
            if additional_high_waypoint_position != Vector2.INF:
                # We are backtracking to consider a new jump height.
                # 
                # The destination jump time should account for all of the
                # following:
                # 
                # -   The time needed to reach any previous jump-heights before
                #     this current round of jump-height backtracking
                #     (vertical_step.time_instruction_end).
                # -   The time needed to reach this new previously-out-of-reach
                #     waypoint.
                # -   The time needed to get to the destination from this new
                #     waypoint.
                
                # TODO: There might be cases that this fails for? We might need
                #       to add more time. Revisit this if we see problems.
                
                var time_to_get_to_destination_from_waypoint := \
                        _calculate_time_to_reach_destination_from_new_waypoint(
                                movement_params,
                                additional_high_waypoint_position,
                                waypoint)
                if is_inf(time_to_get_to_destination_from_waypoint):
                    # We can't reach the destination from this waypoint.
                    return WaypointValidity \
                            .OUT_OF_REACH_FROM_ADDITIONAL_HIGH_WAYPOINT
                
                time_passing_through = max(vertical_step.time_step_end,
                        time_to_pass_through_waypoint_ignoring_others + \
                                time_to_get_to_destination_from_waypoint)
                
            else:
                time_passing_through = \
                        time_to_pass_through_waypoint_ignoring_others
                
                # FIXME: LEFT OFF HERE:
                # - Trying to add support for
                #   waypoint.needs_extra_jump_duration.
                
#                if can_hold_jump_button_at_origin:
#                    # Add a slight constant increase to jump instruction
#                    # durations, to help get over and around surface ends (but
#                    # don't continue the instruction uselessly beyond jump
#                    # height).
#                    var time_to_release_jump_button := VerticalMovementUtils \
#                           .calculate_time_to_release_jump_button(
#                                    movement_params,
#                                    time_passing_through,
#                                    displacement_from_origin_to_waypoint.y,
#                                    velocity_start_origin.y)
#                    # From a basic equation of motion:
#                    #     v = v_0 + a*t
#                    #     v = 0
#                    # Algebra...:
#                    #     t = -v_0/a
#                    var time_to_max_height_with_slow_rise_gravity := \
#                            -velocity_start_origin.y / \
#                            movement_params.gravity_slow_rise
#                    var jump_duration_increase := \
#                            movement_params \
#                                   .exceptional_jump_instruction_duration_increase if \
#                            waypoint.needs_extra_jump_duration else \
#                            movement_params \
#                                   .normal_jump_instruction_duration_increase
#                    # FIXME: Uncomment (since this is the whole point), after
#                    #        getting the rest of this to work (the rest should
#                    #        be a no-op, but seems to break stuff).
##                    time_to_release_jump_button = min(
##                            time_to_release_jump_button + \
##                            jump_duration_increase,
##                            time_to_max_height_with_slow_rise_gravity)
#                    # FIXME: Is this needed?
#                    time_to_release_jump_button -= 0.001
#                    var vertical_state_at_jump_button_release := \
#                            VerticalMovementUtils \
#                                   .calculate_vertical_state_for_time(
#                                           movement_params,
#                                           time_to_release_jump_button,
#                                           origin_waypoint.position.y,
#                                           velocity_start_origin.y,
#                                           time_to_release_jump_button)
#                    var position_y_at_jump_button_release: float = \
#                            vertical_state_at_jump_button_release[0]
#                    var velocity_y_at_jump_button_release: float = \
#                            vertical_state_at_jump_button_release[1]
#                    # From a basic equation of motion:
#                    #     v^2 = v_0^2 + 2*a*(s - s_0)
#                    #     v = v_0 + a*t
#                    # Algebra...:
#                    #     t = (sqrt(v_0^2 + 2*a*(s - s_0)) - v_0) / a
#                    # FIXME: Re-insert these back into one expression.
#                    var foo := velocity_y_at_jump_button_release * \
#                            velocity_y_at_jump_button_release
#                    var disp := waypoint.position.y - \
#                            position_y_at_jump_button_release
#                    var bar := 2 * movement_params.gravity_fast_fall * disp
#                    var baz := sqrt(foo + bar)
#                    var time_to_destination_after_jump_button_release := \
#                            (baz - \
#                            velocity_y_at_jump_button_release) / \
#                            movement_params.gravity_fast_fall
#                    time_passing_through = \
#                            time_to_release_jump_button + \
#                            time_to_destination_after_jump_button_release
#                    # FIXME: Is this needed?
#                    time_passing_through += 0.002
#                    # FIXME: Remove.
#                    if is_nan((time_passing_through - \
#                           time_passing_through) / 2.0):
#                        print("break")
            
            # We can't be more restrictive with the destination velocity
            # limits, because otherwise, origin vs intermediate waypoints give
            # us all sorts of invalid values, which they in-turn base their
            # values off of.
            # 
            # Specifically, when the horizontal movement sign of the
            # destination changes, due to a new intermediate waypoint, either
            # the min or max would be incorrectly capped at 0 when we're
            # calculating the min/max for the new waypoint.
            # 
            # If this was already assigned a min/max (because we need the
            # edge's movement to end in a certain direction), use that;
            # otherwise, use max possible speed values.
            min_velocity_x = \
                    waypoint.min_velocity_x if \
                    !is_inf(waypoint.min_velocity_x) else \
                    -movement_params.get_max_air_horizontal_speed()
            max_velocity_x = \
                    waypoint.max_velocity_x if \
                    !is_inf(waypoint.max_velocity_x) else \
                    movement_params.get_max_air_horizontal_speed()
            
        else:
            # This is an intermediate waypoint (not the origin or destination).
            
            time_passing_through = VerticalMovementUtils \
                    .calculate_time_for_passing_through_waypoint(
                            movement_params,
                            waypoint,
                            waypoint.previous_waypoint.time_passing_through + \
                                    0.0001,
                            vertical_step.position_step_start.y,
                            vertical_step.velocity_step_start.y,
                            vertical_step.time_instruction_end,
                            vertical_step.position_instruction_end.y,
                            vertical_step.velocity_instruction_end.y)
            if is_inf(time_passing_through):
                # We can't reach this waypoint from the previous waypoint.
                return WaypointValidity \
                        .THIS_WAYPOINT_OUT_OF_REACH_FROM_PREVIOUS_WAYPOINT
            
            var still_ascending := \
                    time_passing_through < vertical_step.time_peak_height
            
            # We can quit early for a few types of waypoints.
            if !waypoint.passing_vertically and \
                    waypoint.should_stay_on_min_side and \
                    !still_ascending:
                # Quit early if we are trying to go above a wall, but we are
                # already descending.
                return WaypointValidity \
                        .TRYING_TO_PASS_OVER_WALL_WHILE_DESCENDING
            elif !waypoint.passing_vertically and \
                    !waypoint.should_stay_on_min_side and \
                    still_ascending:
                # Quit early if we are trying to go below a wall, but we are
                # still ascending.
                return WaypointValidity \
                        .TRYING_TO_PASS_UNDER_WALL_WHILE_ASCENDING
            else:
                # We should never hit a floor while still holding the jump
                # button.
                assert(!(waypoint.side == SurfaceSide.FLOOR and \
                        still_ascending))
            
            var duration_to_next := \
                    waypoint.next_waypoint.time_passing_through - \
                    time_passing_through
            if duration_to_next <= 0:
                # We can't reach the next waypoint from this waypoint.
                return WaypointValidity \
                        .NEXT_WAYPOINT_OUT_OF_REACH_FROM_THIS_WAYPOINT
            
            var displacement_to_next := displacement
            var duration_from_origin := \
                    time_passing_through - origin_waypoint.time_passing_through
            var displacement_from_origin := \
                    waypoint.position - origin_waypoint.position
            
            # We calculate min/max velocity limits for direct movement from the
            # origin. These limits are more permissive than if we were
            # calculating them from the actual immediately previous waypoint,
            # but these can give an early indicator for whether this waypoint
            # is invalid.
            # 
            # NOTE: This check will still not guarantee that movement up to
            #       this waypoint can be reached, since any previous
            #       intermediate waypoints could invalidate things.
            var min_and_max_velocity_from_origin := \
                    _calculate_min_and_max_x_velocity_at_end_of_interval(
                            displacement_from_origin.x,
                            duration_from_origin,
                            origin_waypoint.min_velocity_x,
                            origin_waypoint.max_velocity_x,
                            movement_params.get_max_air_horizontal_speed(),
                            movement_params.in_air_horizontal_acceleration,
                            waypoint.horizontal_movement_sign)
            if min_and_max_velocity_from_origin.empty():
                # We can't reach this waypoint from the previous waypoint.
                return WaypointValidity.NO_VALID_VELOCITY_FROM_ORIGIN
            var min_velocity_x_from_origin: float = \
                    min_and_max_velocity_from_origin[0]
            var max_velocity_x_from_origin: float = \
                    min_and_max_velocity_from_origin[1]
            
            # Calculate the min and max velocity for movement through the
            # waypoint, in order for movement to reach the next waypoint.
            var min_and_max_velocity_for_next_step := \
                    _calculate_min_and_max_x_velocity_at_start_of_interval(
                            displacement_to_next.x,
                            duration_to_next,
                            waypoint.next_waypoint.min_velocity_x,
                            waypoint.next_waypoint.max_velocity_x,
                            movement_params.get_max_air_horizontal_speed(),
                            movement_params.in_air_horizontal_acceleration,
                            waypoint.horizontal_movement_sign)
            if min_and_max_velocity_for_next_step.empty():
                # We can't reach the next waypoint from this waypoint.
                return WaypointValidity.NO_VALID_VELOCITY_FOR_NEXT_STEP
            var min_velocity_x_for_next_step: float = \
                    min_and_max_velocity_for_next_step[0]
            var max_velocity_x_for_next_step: float = \
                    min_and_max_velocity_for_next_step[1]
            
            min_velocity_x = max(
                    min_velocity_x_from_origin,
                    min_velocity_x_for_next_step)
            max_velocity_x = min(
                    max_velocity_x_from_origin,
                    max_velocity_x_for_next_step)
        
        # actual_velocity_x is calculated when calculating the horizontal
        # steps.
        actual_velocity_x = INF
    
    waypoint.time_passing_through = time_passing_through
    waypoint.min_velocity_x = min_velocity_x
    waypoint.max_velocity_x = max_velocity_x
    waypoint.actual_velocity_x = actual_velocity_x
    
    # FIXME: DEBUGGING: Maybe remove the is_destination conditional?
    if !waypoint.is_destination:
        # Ensure that the min and max velocities match the expected horizontal
        # movement direction.
        if waypoint.horizontal_movement_sign == 1:
            assert(waypoint.min_velocity_x >= 0 and \
                    waypoint.max_velocity_x >= 0)
        elif waypoint.horizontal_movement_sign == -1:
            assert(waypoint.min_velocity_x <= 0 and \
                    waypoint.max_velocity_x <= 0)
    
    return WaypointValidity.WAYPOINT_VALID


# This only considers the time to move horizontally and the time to fall; this
# does not consider the time to rise from the new waypoint to the destination.
# 
# -   We don't consider rise time, since that would require knowing more
#     information around when the jump button is released and whether it could
#     still be held. Also, this case is much less likely to impact the overall
#     movement duration.
# -   For horizontal movement time, we don't need to know about vertical
#     velocity or the jump button.
# -   For fall time, we can assume that vertical velocity will be zero when
#     passing through this new waypoint (since it should be the highest point
#     we reach in the jump). If the movement would require vertical velocity to
#     _not_ be zero through this new waypoint, then that case should be covered
#     by the horizontal time calculation.
static func _calculate_time_to_reach_destination_from_new_waypoint(
        movement_params: MovementParameters,
        new_waypoint_position: Vector2,
        destination: Waypoint) -> float:
    var displacement := destination.position - new_waypoint_position
    
    var velocity_x_at_new_waypoint: float
    var acceleration: float
    if displacement.x > 0:
        velocity_x_at_new_waypoint = \
                movement_params.get_max_air_horizontal_speed() * \
                CALCULATE_TIME_TO_REACH_DESTINATION_FROM_NEW_WAYPOINT_V_X_MAX_SPEED_MULTIPLIER
        acceleration = movement_params.in_air_horizontal_acceleration
    else:
        velocity_x_at_new_waypoint = \
                -movement_params.get_max_air_horizontal_speed() * \
                CALCULATE_TIME_TO_REACH_DESTINATION_FROM_NEW_WAYPOINT_V_X_MAX_SPEED_MULTIPLIER
        acceleration = -movement_params.in_air_horizontal_acceleration
    
    var time_to_reach_horizontal_displacement := \
            MovementUtils.calculate_duration_for_displacement(
                    displacement.x,
                    velocity_x_at_new_waypoint,
                    acceleration,
                    movement_params.get_max_air_horizontal_speed())
    
    var time_to_reach_fall_displacement: float
    if displacement.y > 0:
        time_to_reach_fall_displacement = \
                MovementUtils.calculate_movement_duration(
                        displacement.y,
                        0.0,
                        movement_params.gravity_fast_fall,
                        true,
                        0.0,
                        true)
    else:
        time_to_reach_fall_displacement = 0.0
    
    return max(
            time_to_reach_horizontal_displacement,
            time_to_reach_fall_displacement)


static func _assign_horizontal_movement_sign(
        waypoint: Waypoint,
        velocity_start_origin: Vector2) -> void:
    var previous_waypoint := waypoint.previous_waypoint
    var next_waypoint := waypoint.next_waypoint
    var is_origin := waypoint.is_origin
    var is_destination := waypoint.is_destination
    var surface := waypoint.surface
    
    assert(surface != null or is_origin or is_destination)
    assert(previous_waypoint != null or is_origin)
    assert(next_waypoint != null or is_destination)
    
    var displacement := \
            waypoint.position - previous_waypoint.position if \
            previous_waypoint != null else \
            next_waypoint.position - waypoint.position
    var neighbor_horizontal_movement_sign := \
            previous_waypoint.horizontal_movement_sign if \
            previous_waypoint != null else \
            next_waypoint.horizontal_movement_sign
    
    var displacement_sign := \
            0 if \
            Sc.geometry.are_floats_equal_with_epsilon(
                    displacement.x,
                    0.0,
                    0.1) else \
            (1 if \
            displacement.x > 0 else \
            -1)
    
    var horizontal_movement_sign_from_displacement := \
            -1 if \
            displacement_sign == -1 else \
            (1 if \
            displacement_sign == 1 else \
            # For straight-vertical steps, if there was any horizontal movement
            # through the previous, then we're going to need to backtrack in
            # the opposition direction to reach the destination.
            (-neighbor_horizontal_movement_sign if \
            !is_inf(neighbor_horizontal_movement_sign) else \
            # For straight vertical steps from the origin, we don't have much
            # to go off of for picking the horizontal movement direction, so
            # just default to rightward for now.
            1))
    
    var horizontal_movement_sign: int
    if is_origin:
        horizontal_movement_sign = \
                1 if \
                velocity_start_origin.x > 0 else \
                (-1 if \
                velocity_start_origin.x < 0 else \
                horizontal_movement_sign_from_displacement)
    elif is_destination:
        horizontal_movement_sign = \
                -1 if \
                surface != null and \
                        surface.side == SurfaceSide.LEFT_WALL else \
                (1 if \
                surface != null and \
                        surface.side == SurfaceSide.RIGHT_WALL else \
                horizontal_movement_sign_from_displacement)
    else:
        horizontal_movement_sign = \
                -1 if \
                surface.side == SurfaceSide.LEFT_WALL else \
                (1 if \
                surface.side == SurfaceSide.RIGHT_WALL else \
                (-1 if \
                waypoint.should_stay_on_min_side else \
                1))
    
    waypoint.horizontal_movement_sign = horizontal_movement_sign
    waypoint.horizontal_movement_sign_from_displacement = \
            horizontal_movement_sign_from_displacement


# This calculates the range of possible x velocities at the start of a movement
# step.
# 
# This takes into consideration both:
# 
# -   the given range of possible step-end x velocities that must be met in
#     order for movement to be valid for the next step,
# -   and the range of possible step-start x velocities that can produce valid
#     movement for the current step.
# 
# An Array is returned:
# 
# -   The first element represents the min velocity.
# -   The second element represents the max velocity.
static func _calculate_min_and_max_x_velocity_at_start_of_interval(
        displacement: float,
        duration: float,
        v_1_min_for_next_waypoint: float,
        v_1_max_for_next_waypoint: float,
        speed_max: float,
        a_magnitude: float,
        start_horizontal_movement_sign: int) -> Array:
    ### Calculate more tightly-bounded min/max end velocity values, according
    ### to both the duration of the current step and the given min/max values
    ### from the next waypoint.
    
    # The strategy here, is to first try min/max v_1 values that correspond to
    # accelerating over the entire interval. If they do not result in movement
    # that exceeds max speed, then we know that they are the most extreme
    # possible end velocities. Otherwise, if the movement would exceed max
    # speed, then we need to perform a slightly more expensive calculation
    # that assumes a two-part movement profile: one part with constant
    # acceleration and one part with constant velocity.
    
    # Accelerating in a positive direction over the entire step corresponds to
    # an upper bound on the end velocity and a lower boound on the start
    # velocity, and accelerating in a negative direction over the entire step
    # corresponds to a lower bound on the end velocity and an upper bound on
    # the start velocity.
    # 
    # Derivation:
    # - From basic equations of motion:
    #   s = s_0 + v_0*t + 1/2*a*t^2
    #   v_1 = v_0 + a*t
    # - Algebra...
    #   v_1 = (s - s_0) / t + 1/2*a*t
    var min_v_1_with_complete_neg_acc_and_no_max_speed := \
            displacement / duration - 0.5 * a_magnitude * duration
    var max_v_1_with_complete_pos_acc_and_no_max_speed := \
            displacement / duration + 0.5 * a_magnitude * duration
    
    # From a basic equation of motion:
    #   v = v_0 + a*t
    var max_v_0_with_complete_neg_acc_and_no_max_speed := \
            min_v_1_with_complete_neg_acc_and_no_max_speed + \
            a_magnitude * duration
    var min_v_0_with_complete_pos_acc_and_no_max_speed := \
            max_v_1_with_complete_pos_acc_and_no_max_speed - \
            a_magnitude * duration
    
    var would_complete_neg_acc_exceed_max_speed_at_v_0 := \
            max_v_0_with_complete_neg_acc_and_no_max_speed > speed_max
    var would_complete_pos_acc_exceed_max_speed_at_v_0 := \
            min_v_0_with_complete_pos_acc_and_no_max_speed < -speed_max
    
    var min_v_1_from_partial_acc_and_no_max_speed_at_v_1: float
    var max_v_1_from_partial_acc_and_no_max_speed_at_v_1: float
    
    if would_complete_neg_acc_exceed_max_speed_at_v_0:
        # Accelerating over the entire step to min_v_1_that_can_be_reached
        # would require starting with a velocity that exceeds max speed. So we
        # need to instead consider a two-part movement profile when calculating
        # min_v_1_that_can_be_reached: constant velocity followed by constant
        # acceleration. Accelerating at the end, given the same start velocity,
        # should result in a more extreme end velocity, than accelerating at
        # the start.
        var acceleration := -a_magnitude
        var v_0 := speed_max
        min_v_1_from_partial_acc_and_no_max_speed_at_v_1 = \
                _calculate_v_1_with_v_0_limit(
                        displacement,
                        duration,
                        v_0,
                        acceleration,
                        true)
        if is_inf(min_v_1_from_partial_acc_and_no_max_speed_at_v_1):
            # We cannot reach this waypoint from the previous waypoint.
            return []
    else:
        min_v_1_from_partial_acc_and_no_max_speed_at_v_1 = \
                min_v_1_with_complete_neg_acc_and_no_max_speed
    
    if would_complete_pos_acc_exceed_max_speed_at_v_0:
        # Accelerating over the entire step to max_v_1_that_can_be_reached
        # would require starting with a velocity that exceeds max speed. So we
        # need to instead consider a two-part movement profile when calculating
        # max_v_1_that_can_be_reached: constant velocity followed by constant
        # acceleration. Accelerating at the end, given the same start velocity,
        # should result in a more extreme end velocity, than accelerating at
        # the start.
        var acceleration := a_magnitude
        var v_0 := -speed_max
        max_v_1_from_partial_acc_and_no_max_speed_at_v_1 = \
                _calculate_v_1_with_v_0_limit(
                        displacement,
                        duration,
                        v_0,
                        acceleration,
                        false)
        if is_inf(max_v_1_from_partial_acc_and_no_max_speed_at_v_1):
            # We cannot reach this waypoint from the previous waypoint.
            return []
    else:
        max_v_1_from_partial_acc_and_no_max_speed_at_v_1 = \
                max_v_1_with_complete_pos_acc_and_no_max_speed
    
    # The min and max possible v_1 are dependent on both the duration of the
    # current step and the min and max possible start velocity from the next
    # step, respectively.
    # 
    # The min/max from the next waypoint will not exceed max speed, so it
    # doesn't matter if min_/max_v_1_from_partial_acc_and_no_max_speed exceed
    # max speed.
    var v_1_min := max(min_v_1_from_partial_acc_and_no_max_speed_at_v_1,
            v_1_min_for_next_waypoint)
    var v_1_max := min(max_v_1_from_partial_acc_and_no_max_speed_at_v_1,
            v_1_max_for_next_waypoint)
    
    if v_1_min > v_1_max:
        # Neither direction of acceleration will work with the given min/max
        # velocities from the next waypoint.
        return []
    
    ### Calculate min/max start velocities according to the min/max end
    ### velocities.
    
    # At this point, there are a few different parameters we can adjust in
    # order to define the movement from the previous waypoint to the next (and
    # to define the start velocity). These parameters include:
    # 
    # -   The end velocity.
    # -   The direction of acceleration.
    # -   When during the interval to apply acceleration (in this function, we
    #     only need to consider acceleration at the very end or the very
    #     beginning of the step, since those will correspond to upper and lower
    #     bounds on the start velocity).
    # 
    # The general strategy then is to pick values for these parameters that
    # will produce the most extreme start velocities. We then calculate a few
    # possible combinations of these parameters, and return the resulting
    # min/max start velocities. This should work, because any velocity between
    # the resulting min and max should be achievable (since the actual final
    # movement will support applying acceleration at any point in the middle of
    # the step).
    #
    # Some notes about parameter selection:
    # 
    # -   Min and max end velocities correspond to max and min start
    #     velocities, respectively.
    # -   If negative acceleration is used during this interval, then we want
    #     to accelerate at the start of the interval to find the max start
    #     velocity and accelerate at the end of the interval to find the min
    #     start velocity.
    # -   If positive acceleration is used during this interval, then we want
    #     to accelerate at the end of the interval to find the max start
    #     velocity and accelerate at the start of the interval to find the min
    #     start velocity.
    # -   All of the above is true regardless of the direction of displacement
    #     for the interval.
    
    # FIXME: If I see any problems from this logic, then just calculate the
    #        other four cases too, and use the best valid ones from the whole
    #        set of 8.
    
    var v_1: float
    var acceleration: float
    var should_accelerate_at_start: bool
    var should_return_min_result: bool
    var v_0_min: float
    var v_0_max: float
    
    if would_complete_neg_acc_exceed_max_speed_at_v_0:
        v_1 = v_1_min
        acceleration = -a_magnitude
        should_accelerate_at_start = true
        should_return_min_result = false
        var v_0_max_neg_acc_at_start := _solve_for_start_velocity(
                displacement,
                duration,
                acceleration,
                v_1,
                should_accelerate_at_start,
                should_return_min_result)
        
        v_1 = v_1_min
        acceleration = a_magnitude
        should_accelerate_at_start = false
        should_return_min_result = false
        var v_0_max_pos_acc_at_end := _solve_for_start_velocity(
                displacement,
                duration,
                acceleration,
                v_1,
                should_accelerate_at_start,
                should_return_min_result)
        
        # Use the more extreme of the possible min/max values we calculated for
        # positive/negative acceleration at the start/end.
        v_0_max = \
                max(v_0_max_neg_acc_at_start, v_0_max_pos_acc_at_end) if \
                        !is_inf(v_0_max_neg_acc_at_start) and \
                        !is_inf(v_0_max_pos_acc_at_end) else \
                (v_0_max_neg_acc_at_start if \
                !is_inf(v_0_max_neg_acc_at_start) else \
                v_0_max_pos_acc_at_end)
    else:
        # FIXME: LEFT OFF HERE: Does this need to account for accurate
        # displacement values or anything?
        
        # - From a basic equation of motion:
        #   v = v_0 + a*t
        # - Uses negative acceleration.
        v_0_max = v_1_min + a_magnitude * duration
    
    if would_complete_pos_acc_exceed_max_speed_at_v_0:
        v_1 = v_1_max
        acceleration = a_magnitude
        should_accelerate_at_start = true
        should_return_min_result = true
        var v_0_min_pos_acc_at_start := _solve_for_start_velocity(
                displacement,
                duration,
                acceleration,
                v_1,
                should_accelerate_at_start,
                should_return_min_result)
        
        v_1 = v_1_max
        acceleration = -a_magnitude
        should_accelerate_at_start = false
        should_return_min_result = true
        var v_0_min_neg_acc_at_end := _solve_for_start_velocity(
                displacement,
                duration,
                acceleration,
                v_1,
                should_accelerate_at_start,
                should_return_min_result)
        
        # Use the more extreme of the possible min/max values we calculated for
        # positive/negative acceleration at the start/end.
        v_0_min = \
                min(v_0_min_pos_acc_at_start, v_0_min_neg_acc_at_end) if \
                        !is_inf(v_0_min_pos_acc_at_start) and \
                        !is_inf(v_0_min_neg_acc_at_end) else \
                (v_0_min_pos_acc_at_start if \
                !is_inf(v_0_min_pos_acc_at_start) else \
                v_0_min_neg_acc_at_end)
    else:
        # FIXME: LEFT OFF HERE: Does this need to account for accurate
        # displacement values or anything?
        
        # - From a basic equation of motion:
        #   v = v_0 + a*t
        # - Uses positive acceleration.
        v_0_min = v_1_max - a_magnitude * duration
    
    ### Sanitize the results (remove invalid results, cap values, correct for
    ### round-off errors).
    
    # If we found valid v_1_min/v_1_max values, then there must be valid
    # corresponding v_0_min/v_0_max values.
    assert(!is_inf(v_0_max))
    assert(!is_inf(v_0_min))
    assert(v_0_max >= v_0_min)
    
    # Add a small offset to the min and max to help with round-off errors.
    v_0_min += MIN_MAX_VELOCITY_X_OFFSET
    v_0_max -= MIN_MAX_VELOCITY_X_OFFSET
    
    # Correct small floating-point errors around zero.
    if Sc.geometry.are_floats_equal_with_epsilon(
            v_0_min,
            0.0,
            MIN_MAX_VELOCITY_X_OFFSET * 1.1):
        v_0_min = 0.0
    if Sc.geometry.are_floats_equal_with_epsilon(
            v_0_max,
            0.0,
            MIN_MAX_VELOCITY_X_OFFSET * 1.1):
        v_0_max = 0.0
    
    if (start_horizontal_movement_sign > 0 and v_0_max < 0) or \
        (start_horizontal_movement_sign < 0 and v_0_min > 0):
        # We cannot reach the next waypoint with the needed movement direction.
        return []
    
    # Limit velocity to the expected movement direction for this waypoint.
    if start_horizontal_movement_sign > 0:
        v_0_min = max(v_0_min, 0.0)
    else:
        v_0_max = min(v_0_max, 0.0)
    
    # Limit max speeds.
    if v_0_min > speed_max or v_0_max < -speed_max:
        # We cannot reach the next waypoint from the previous waypoint.
        return []
    v_0_max = min(v_0_max, speed_max)
    v_0_min = max(v_0_min, -speed_max)
    
    return [v_0_min, v_0_max]


# Accelerating over the whole interval would result in an end velocity that
# exceeds the max speed. So instead, we assume a 2-part movement profile with
# constant velocity in the first part and constant acceleration in the second
# part. This 2-part movement should more accurately represent the limit on v_1.
static func _calculate_v_1_with_v_0_limit(
        displacement: float,
        duration: float,
        v_0: float,
        acceleration: float,
        should_return_min_result: bool) -> float:
    # Derivation:
    # - From basic equations of motion:
    #   - s_1 = s_0 + v_0*t_0
    #   - v_1 = v_0 + a*t_1
    #   - v_1^2 = v_0^2 + 2*a*(s_2 - s_1)
    #   - t_total = t_0 + t_1
    #   - diplacement = s_2 - s_0
    # - Do some algebra...
    #   - 0 = 2*a*(displacement - v_0*t_total) - v_0^2 + 2*v_0*v_1 - v_1^2
    # - Apply quadratic formula to solve for v_1.
    
    var a := -1
    var b := 2 * v_0
    var c := 2 * acceleration * (displacement - v_0 * duration) - v_0 * v_0
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # There is no end velocity that can satisfy these parameters.
        return INF
    
    var discriminant_sqrt := sqrt(discriminant)
    var result_1 := (-b + discriminant_sqrt) / 2.0 / a
    var result_2 := (-b - discriminant_sqrt) / 2.0 / a
    
    # From a basic equation of motion:
    #    v_1 = v_0 + a*t
    var t_result_1 := (result_1 - v_0) / acceleration
    var t_result_2 := (result_2 - v_0) / acceleration
    
    # The results are invalid if they correspond to imaginary negative
    # durations.
    var is_result_1_valid := (t_result_1 >= 0 and t_result_1 <= duration)
    var is_result_2_valid := (t_result_2 >= 0 and t_result_2 <= duration)
    
    if !is_result_1_valid and !is_result_2_valid:
        # There is no end velocity that can satisfy these parameters.
        return INF
    elif !is_result_1_valid:
        return result_2
    elif !is_result_2_valid:
        return result_1
    elif should_return_min_result:
        return min(result_1, result_2)
    else:
        return max(result_1, result_2)


static func _solve_for_start_velocity(
        displacement: float,
        duration: float,
        acceleration: float,
        v_1: float,
        should_accelerate_at_start: bool,
        should_return_min_result: bool) -> float:
    var acceleration_sign := 1 if acceleration >= 0 else -1
    
    var a: float
    var b: float
    var c: float
    
    # We only need to consider two movement profiles:
    # 
    # -   Accelerate at start (2 parts):
    #     -   First, constant acceleration to v_1.
    #     -   Then, constant velocity at v_1 for the remaining duration.
    # -   Accelerate at end (2 parts):
    #     -   First, constant velocity at v_0.
    #     -   Then, constant acceleration for the remaining duration, ending at
    #         v_1.
    # 
    # No other movement profile--e.g., 3-part with constant v at v_0,
    # accelerate to v_1, constant v at v_1--should produce more extreme start
    # velocities, so we only need to consider these two. Any considerations for
    # capping at max-speed will be handled by the consumer function that calls
    # this one.
    
    if should_accelerate_at_start:
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant acceleration from v_0 to v_1.
        #   - Part 2: Coast at v_1 until we reach the destination.
        # - Start with basic equations of motion:
        #   - v_1 = v_0 + a*t_0
        #   - s_2 = s_1 + v_1*t_1
        #   - v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
        #   - t_total = t_0 + t_1
        #   - displacement = s_2 - s_0
        # - Do some algebra...
        #   - 0 = 2*a*(displacement - v_1*t) + v_1^2 - 2*v_1*v_0 + v_0^2
        # - Apply quadratic formula to solve for v_0.
        a = 1
        b = -2 * v_1
        c = 2 * acceleration * (displacement - v_1 * duration) + v_1 * v_1
    else:
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant velocity at v_0.
        #   - Part 2: Constant acceleration for the remaining duration, ending
        #     at v_1.
        # - Start with basic equations of motion:
        #   - s_1 = s_0 + v_0*t_0
        #   - v_1 = v_0 + a*t_1
        #   - v_1^2 = v_0^2 + 2*a*(s_2 - s_1)
        #   - t_total = t_0 + t_1
        #   - displacement = s_2 - s_0
        # - Do some algebra...
        #   - 0 = 2*a*displacement - v_1^2 + 2*(v_1 - a*t_total)*v_0 - v_0^2
        # - Apply quadratic formula to solve for v_0.
        a = -1
        b = 2 * (v_1 - acceleration * duration)
        c = 2 * acceleration * displacement - v_1 * v_1
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # There is no start velocity that can satisfy these parameters.
        return INF
    
    var discriminant_sqrt := sqrt(discriminant)
    var result_1 := (-b + discriminant_sqrt) / 2.0 / a
    var result_2 := (-b - discriminant_sqrt) / 2.0 / a
    
    # From a basic equation of motion:
    #    v = v_0 + a*t
    var t_result_1 := (v_1 - result_1) / acceleration
    var t_result_2 := (v_1 - result_2) / acceleration
    
    ###########################################
    # FIXME: REMOVE: DEBUGGING:
#    var disp_result_1_foo := \
#            v_0*t_result_1 + 0.5*acceleration*t_result_1*t_result_1
#    var disp_result_1_bar := result_1*(duration-t_result_1)
#    var disp_result_1_total := disp_result_1_foo + disp_result_1_bar
#    var disp_result_2_foo := \
#            v_0*t_result_2 + 0.5*acceleration*t_result_2*t_result_2
#    var disp_result_2_bar := result_2*(duration-t_result_2)
#    var disp_result_2_total := disp_result_2_foo + disp_result_2_bar
    ###########################################
    
    # The results are invalid if they correspond to imaginary negative
    # durations.
    var is_result_1_valid := t_result_1 >= 0 and t_result_1 <= duration
    var is_result_2_valid := t_result_2 >= 0 and t_result_2 <= duration
    
    if !is_result_1_valid and !is_result_2_valid:
        # There is no start velocity that can satisfy these parameters.
        return INF
    elif !is_result_1_valid:
        return result_2
    elif !is_result_2_valid:
        return result_1
    elif should_return_min_result:
        return min(result_1, result_2)
    else:
        return max(result_1, result_2)


# This calculates the range of possible x velocities at the end of a movement
# step.
# 
# This takes into consideration both:
# 
# -   the given range of possible step-start x velocities that must be met in
#     order for movement to be valid for the previous step,
# -   and the range of possible step-end x velocities that can produce valid
#     movement for the current step.
# 
# An Array is returned:
# 
# -   The first element represents the min velocity.
# -   The second element represents the max velocity.
static func _calculate_min_and_max_x_velocity_at_end_of_interval(
        displacement: float,
        duration: float,
        v_1_min_for_previous_waypoint: float,
        v_1_max_for_previous_waypoint: float,
        speed_max: float,
        a_magnitude: float,
        end_horizontal_movement_sign: int) -> Array:
    ### Calculate more tightly-bounded min/max start velocity values, according
    ### to both the duration of the current step and the given min/max values
    ### from the previous waypoint.
    
    # The strategy here, is to first try min/max v_0 values that correspond to
    # accelerating over the entire interval. If they do not result in movement
    # that exceeds max speed, then we know that they are the most extreme
    # possible start velocities. Otherwise, if the movement would exceed max
    # speed, then we need to perform a slightly more expensive calculation that
    # assumes a two-part movement profile: one part with constant acceleration
    # and one part with constant velocity.
    
    # Accelerating in a positive direction over the entire step corresponds to
    # an upper bound on the end velocity and a lower boound on the start
    # velocity, and accelerating in a negative direction over the entire step
    # corresponds to a lower bound on the end velocity and an upper bound on
    # the start velocity.
    # 
    # Derivation:
    # - From basic equations of motion:
    #   s = s_0 + v_0*t + 1/2*a*t^2
    # - Algebra...
    #   v_0 = (s - s_0) / t - 1/2*a*t
    var min_v_0_with_complete_pos_acc_and_no_max_speed := \
            displacement / duration - 0.5 * a_magnitude * duration
    var max_v_0_with_complete_neg_acc_and_no_max_speed := \
            displacement / duration + 0.5 * a_magnitude * duration
    
    # From a basic equation of motion:
    #   v_1 = v_0 + a*t
    var max_v_1_with_complete_pos_acc_and_no_max_speed := \
            min_v_0_with_complete_pos_acc_and_no_max_speed + \
            a_magnitude * duration
    var min_v_1_with_complete_neg_acc_and_no_max_speed := \
            max_v_0_with_complete_neg_acc_and_no_max_speed - \
            a_magnitude * duration
    
    var would_complete_pos_acc_exceed_max_speed_at_v_1 := \
            max_v_1_with_complete_pos_acc_and_no_max_speed > speed_max
    var would_complete_neg_acc_exceed_max_speed_at_v_1 := \
            min_v_1_with_complete_neg_acc_and_no_max_speed < -speed_max
    
    var min_v_0_from_partial_acc_and_no_max_speed_at_v_0: float
    var max_v_0_from_partial_acc_and_no_max_speed_at_v_0: float
    
    if would_complete_pos_acc_exceed_max_speed_at_v_1:
        # Accelerating over the entire step to min_v_0_that_can_reach_target
        # would require ending with a velocity that exceeds max speed. So we
        # need to instead consider a two-part movement profile when calculating
        # min_v_0_that_can_reach_target: constant acceleration followed by
        # constant velocity. Accelerating at the start, given the same end
        # velocity, should result in a more extreme start velocity, than
        # accelerating at the end.
        var acceleration := a_magnitude
        var v_1 := speed_max
        min_v_0_from_partial_acc_and_no_max_speed_at_v_0 = \
                _calculate_v_0_with_v_1_limit(
                        displacement,
                        duration,
                        v_1,
                        acceleration,
                        true)
        if is_inf(min_v_0_from_partial_acc_and_no_max_speed_at_v_0):
            # We cannot reach this waypoint from the previous waypoint.
            return []
    else:
        min_v_0_from_partial_acc_and_no_max_speed_at_v_0 = \
                min_v_0_with_complete_pos_acc_and_no_max_speed
    
    if would_complete_neg_acc_exceed_max_speed_at_v_1:
        # Accelerating over the entire step to max_v_0_that_can_reach_target
        # would require ending with a velocity that exceeds max speed. So we
        # need to instead consider a two-part movement profile when calculating
        # max_v_0_that_can_reach_target: constant acceleration followed by
        # constant velocity. Accelerating at the start, given the same end
        # velocity, should result in a more extreme start velocity, than
        # accelerating at the end.
        var acceleration := -a_magnitude
        var v_1 := -speed_max
        max_v_0_from_partial_acc_and_no_max_speed_at_v_0 = \
                _calculate_v_0_with_v_1_limit(
                        displacement,
                        duration,
                        v_1,
                        acceleration,
                        false)
        if is_inf(max_v_0_from_partial_acc_and_no_max_speed_at_v_0):
            # We cannot reach this waypoint from the previous waypoint.
            return []
    else:
        max_v_0_from_partial_acc_and_no_max_speed_at_v_0 = \
                max_v_0_with_complete_neg_acc_and_no_max_speed
    
    # The min and max possible v_0 are dependent on both the duration of the
    # current step and the min and max possible end velocity from the previous
    # step, respectively.
    # 
    # The min/max from the previous waypoint will not exceed max speed, so it
    # doesn't matter if min_/max_v_0_from_partial_acc_and_no_max_speed exceed
    # max speed.
    var v_0_min := max(min_v_0_from_partial_acc_and_no_max_speed_at_v_0,
            v_1_min_for_previous_waypoint)
    var v_0_max := min(max_v_0_from_partial_acc_and_no_max_speed_at_v_0,
            v_1_max_for_previous_waypoint)
    
    if v_0_min > v_0_max:
        # Neither direction of acceleration will work with the given min/max
        # velocities from the previous waypoint.
        return []
    
    ### Calculate min/max end velocities according to the min/max start
    ### velocities.
    
    # At this point, there are a few different parameters we can adjust in
    # order to define the movement from the previous waypoint to the next (and
    # to define the start velocity). These parameters include:
    # 
    # -   The start velocity.
    # -   The direction of acceleration.
    # -   When during the interval to apply acceleration (in this function, we
    #     only need to consider acceleration at the very end or the very
    #     beginning of the step, since those will correspond to upper and lower
    #     bounds on the end velocity).
    # 
    # The general strategy then is to pick values for these parameters that
    # will produce the most extreme end velocities. We then calculate a few
    # possible combinations of these parameters, and return the resulting
    # min/max end velocities. This should work, because any velocity between
    # the resulting min and max should be achievable (since the actual final
    # movement will support applying acceleration at any point in the middle of
    # the step).
    #
    # Some notes about parameter selection:
    # 
    # -   Min and max start velocities correspond to max and min end
    #     velocities, respectively.
    # -   If negative acceleration is used during this interval, then we want
    #     to accelerate at the start of the interval to find the max end
    #     velocity and accelerate at the end of the interval to find the min
    #     end velocity.
    # -   If positive acceleration is used during this interval, then we want
    #     to accelerate at the end of the interval to find the max end velocity
    #     and accelerate at the start of the interval to find the min end
    #     velocity.
    # -   All of the above is true regardless of the direction of displacement
    #     for the interval.
    
    # FIXME: If I see any problems from this logic, then just calculate the
    #        other four cases too, and use the best valid ones from the whole
    #        set of 8.
    
    var v_0: float
    var acceleration: float
    var should_accelerate_at_start: bool
    var should_return_min_result: bool
    var v_1_min: float
    var v_1_max: float
    
    if would_complete_pos_acc_exceed_max_speed_at_v_1:
        v_0 = v_0_min
        acceleration = -a_magnitude
        should_accelerate_at_start = true
        should_return_min_result = false
        var v_1_max_neg_acc_at_start := _solve_for_end_velocity(
                displacement,
                duration,
                acceleration,
                v_0,
                should_accelerate_at_start,
                should_return_min_result)
        
        v_0 = v_0_min
        acceleration = a_magnitude
        should_accelerate_at_start = false
        should_return_min_result = false
        var v_1_max_pos_acc_at_end := _solve_for_end_velocity(
                displacement,
                duration,
                acceleration,
                v_0,
                should_accelerate_at_start,
                should_return_min_result)
        
        # Use the more extreme of the possible min/max values we calculated for
        # positive/negative acceleration at the start/end.
        v_1_max = \
                max(v_1_max_neg_acc_at_start, v_1_max_pos_acc_at_end) if \
                        !is_inf(v_1_max_neg_acc_at_start) and \
                        !is_inf(v_1_max_pos_acc_at_end) else \
                (v_1_max_neg_acc_at_start if \
                !is_inf(v_1_max_neg_acc_at_start) else \
                v_1_max_pos_acc_at_end)
    else:
        # FIXME: LEFT OFF HERE: Does this need to account for accurate
        #        displacement values or anything?
        
        # - From a basic equation of motion:
        #   v = v_0 + a*t
        # - Uses positive acceleration.
        v_1_max = v_0_min + a_magnitude * duration
    
    if would_complete_neg_acc_exceed_max_speed_at_v_1:
        v_0 = v_0_max
        acceleration = a_magnitude
        should_accelerate_at_start = true
        should_return_min_result = true
        var v_1_min_pos_acc_at_start := _solve_for_end_velocity(
                displacement,
                duration,
                acceleration,
                v_0,
                should_accelerate_at_start,
                should_return_min_result)
        
        v_0 = v_0_max
        acceleration = -a_magnitude
        should_accelerate_at_start = false
        should_return_min_result = true
        var v_1_min_neg_acc_at_end := _solve_for_end_velocity(
                displacement,
                duration,
                acceleration,
                v_0,
                should_accelerate_at_start,
                should_return_min_result)
        
        # Use the more extreme of the possible min/max values we calculated for
        # positive/negative acceleration at the start/end.
        v_1_min = \
                min(v_1_min_pos_acc_at_start, v_1_min_neg_acc_at_end) if \
                        !is_inf(v_1_min_pos_acc_at_start) and \
                        !is_inf(v_1_min_neg_acc_at_end) else \
                (v_1_min_pos_acc_at_start if \
                !is_inf(v_1_min_pos_acc_at_start) else \
                v_1_min_neg_acc_at_end)
    else:
        # FIXME: LEFT OFF HERE: Does this need to account for accurate
        #        displacement values or anything?
        
        # - From a basic equation of motion:
        #   v = v_0 + a*t
        # - Uses negative acceleration.
        v_1_min = v_0_max - a_magnitude * duration
    
    ### Sanitize the results (remove invalid results, cap values, correct for
    ### round-off errors).
    
    # If we found valid v_1_min/v_1_max values, then there must be valid
    # corresponding v_1_min/v_1_max values.
    assert(!is_inf(v_1_max))
    assert(!is_inf(v_1_min))
    assert(v_1_max >= v_1_min)
    
    # Add a small offset to the min and max to help with round-off errors.
    v_1_min += MIN_MAX_VELOCITY_X_OFFSET
    v_1_max -= MIN_MAX_VELOCITY_X_OFFSET
    
    # Correct small floating-point errors around zero.
    if Sc.geometry.are_floats_equal_with_epsilon(
            v_1_min,
            0.0,
            MIN_MAX_VELOCITY_X_OFFSET * 1.1):
        v_1_min = 0.0
    if Sc.geometry.are_floats_equal_with_epsilon(
            v_1_max,
            0.0,
            MIN_MAX_VELOCITY_X_OFFSET * 1.1):
        v_1_max = 0.0
    
    if (end_horizontal_movement_sign > 0 and v_1_max < 0) or \
        (end_horizontal_movement_sign < 0 and v_1_min > 0):
        # We cannot reach this waypoint with the needed movement direction.
        return []
    
    # Limit velocity to the expected movement direction for this waypoint.
    if end_horizontal_movement_sign > 0:
        v_1_min = max(v_1_min, 0.0)
    else:
        v_1_max = min(v_1_max, 0.0)
    
    # Limit max speeds.
    if v_1_min > speed_max or v_1_max < -speed_max:
        # We cannot reach this waypoint from the previous waypoint.
        return []
    v_1_max = min(v_1_max, speed_max)
    v_1_min = max(v_1_min, -speed_max)
    
    return [v_1_min, v_1_max]


# Accelerating over the whole interval would result in an end velocity that
# exceeds the max speed. So instead, we assume a 2-part movement profile with
# constant acceleration in the first part and constant velocity in the second
# art. This 2-part movement should more accurately represent the limit on v_0.
static func _calculate_v_0_with_v_1_limit(
        displacement: float,
        duration: float,
        v_1: float,
        acceleration: float,
        should_return_min_result: bool) -> float:
    # Derivation:
    # - From basic equations of motion:
    #   - v_1 = v_0 + a*t_0
    #   - s_2 = s_1 + v_1*t_1
    #   - v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
    #   - t_total = t_0 + t_1
    #   - diplacement = s_2 - s_0
    # - Do some algebra...
    #   - 0 = displacement*a/v_1 + 1/2*v_1 - a*t_total - v_0 + 1/2/v_1*v_0^2
    # - Apply quadratic formula to solve for v_1.
    
    var a := 0.5 / v_1
    var b := -1
    var c := displacement * acceleration / v_1 + 0.5 * v_1 - \
            acceleration * duration
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # There is no start velocity that can satisfy these parameters.
        return INF
    
    var discriminant_sqrt := sqrt(discriminant)
    var result_1 := (-b + discriminant_sqrt) / 2.0 / a
    var result_2 := (-b - discriminant_sqrt) / 2.0 / a
    
    # From a basic equation of motion:
    #    v = v_0 + a*t
    var t_result_1 := (v_1 - result_1) / acceleration
    var t_result_2 := (v_1 - result_2) / acceleration
    
    # The results are invalid if they correspond to imaginary negative
    # durations.
    var is_result_1_valid := (t_result_1 >= 0 and t_result_1 <= duration)
    var is_result_2_valid := (t_result_2 >= 0 and t_result_2 <= duration)
    
    if !is_result_1_valid and !is_result_2_valid:
        # There is no start velocity that can satisfy these parameters.
        return INF
    elif !is_result_1_valid:
        return result_2
    elif !is_result_2_valid:
        return result_1
    elif should_return_min_result:
        return min(result_1, result_2)
    else:
        return max(result_1, result_2)


static func _solve_for_end_velocity(
        displacement: float,
        duration: float,
        acceleration: float,
        v_0: float,
        should_accelerate_at_start: bool,
        should_return_min_result: bool) -> float:
    var acceleration_sign := 1 if acceleration >= 0 else -1
    
    var a: float
    var b: float
    var c: float
    
    # We only need to consider two movement profiles:
    # 
    # -   Accelerate at start (2 parts):
    #     -   First, constant acceleration to v_1.
    #     -   Then, constant velocity at v_1 for the remaining duration.
    # -   Accelerate at end (2 parts):
    #     -   First, constant velocity at v_0.
    #     -   Then, constant acceleration for the remaining duration, ending at
    #         v_1.
    # 
    # No other movement profile--e.g., 3-part with constant v at v_0,
    # accelerate to v_1, constant v at v_1--should produce more extreme end
    # velocities, so we only need to consider these two. Any considerations for
    # capping at max-speed will be handled by the consumer function that calls
    # this one.
    
    if should_accelerate_at_start:
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant acceleration from v_0 to v_1.
        #   - Part 2: Coast at v_1 until we reach the destination.
        # - Start with basic equations of motion:
        #   - v_1 = v_0 + a*t_0
        #   - s_2 = s_1 + v_1*t_1
        #   - v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
        #   - t_total = t_0 + t_1
        #   - displacement = s_2 - s_0
        # - Do some algebra...
        #   - 0 = 2*a*displacement + v_0^2 - 2*(a*t_total + v_0)*v_1 + v_1^2
        # - Apply quadratic formula to solve for v_1.
        a = 1
        b = -2 * (acceleration * duration + v_0)
        c = 2 * acceleration * displacement + v_0 * v_0
    else:
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant velocity at v_0.
        #   - Part 2: Constant acceleration for the remaining duration, ending
        #     at v_1.
        # - Start with basic equations of motion:
        #   - s_1 = s_0 + v_0*t_0
        #   - v_1 = v_0 + a*t_1
        #   - v_1^2 = v_0^2 + 2*a*(s_2 - s_1)
        #   - t_total = t_0 + t_1
        #   - displacement = s_2 - s_0
        # - Do some algebra...
        #   - 0 = 2*a*(displacement - t_total*v_0) - v_0^2 + 2*v_0*v_1 - v_1^2
        # - Apply quadratic formula to solve for v_1.
        a = -1
        b = 2 * v_0
        c = 2 * acceleration * (displacement - duration * v_0) - v_0 * v_0
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # There is no end velocity that can satisfy these parameters.
        return INF
    
    var discriminant_sqrt := sqrt(discriminant)
    var result_1 := (-b + discriminant_sqrt) / 2.0 / a
    var result_2 := (-b - discriminant_sqrt) / 2.0 / a
    
    # From a basic equation of motion:
    #    v = v_0 + a*t
    var t_result_1 := (result_1 - v_0) / acceleration
    var t_result_2 := (result_2 - v_0) / acceleration
    
    ###########################################
    # FIXME: REMOVE: DEBUGGING:
#    var disp_result_1_foo := \
#            v_0*t_result_1 + 0.5*acceleration*t_result_1*t_result_1
#    var disp_result_1_bar := result_1*(duration-t_result_1)
#    var disp_result_1_total := disp_result_1_foo + disp_result_1_bar
#    var disp_result_2_foo := \
#            v_0*t_result_2 + 0.5*acceleration*t_result_2*t_result_2
#    var disp_result_2_bar := result_2*(duration-t_result_2)
#    var disp_result_2_total := disp_result_2_foo + disp_result_2_bar
    ###########################################
    
    # The results are invalid if they correspond to imaginary negative
    # durations.
    var is_result_1_valid := t_result_1 >= 0 and t_result_1 <= duration
    var is_result_2_valid := t_result_2 >= 0 and t_result_2 <= duration
    
    if !is_result_1_valid and !is_result_2_valid:
        # There is no end velocity that can satisfy these parameters.
        return INF
    elif !is_result_1_valid:
        return result_2
    elif !is_result_2_valid:
        return result_1
    elif should_return_min_result:
        return min(result_1, result_2)
    else:
        return max(result_1, result_2)


static func update_neighbors_for_new_waypoint(
        waypoint: Waypoint,
        previous_waypoint: Waypoint,
        next_waypoint: Waypoint,
        edge_calc_params: EdgeCalcParams,
        vertical_step: VerticalEdgeStep) -> void:
    var original_previous_waypoint_actual_velocity_x := \
            previous_waypoint.actual_velocity_x
    update_waypoint(
            previous_waypoint,
            edge_calc_params.origin_waypoint,
            edge_calc_params.movement_params,
            vertical_step.velocity_step_start,
            vertical_step.can_hold_jump_button,
            vertical_step,
            Vector2.INF)
    # We don't want to overwrite the actual_velocity_x value, since a new later
    # waypoint shouldn't affect the already-calculated actual velocity through
    # the previous waypoint.
    previous_waypoint.actual_velocity_x = \
            original_previous_waypoint_actual_velocity_x
    update_waypoint(
            next_waypoint,
            edge_calc_params.origin_waypoint,
            edge_calc_params.movement_params,
            vertical_step.velocity_step_start,
            vertical_step.can_hold_jump_button,
            vertical_step,
            Vector2.INF)


static func _calculate_replacement_for_fake_waypoint(
        fake_waypoint: Waypoint,
        waypoint_offset: Vector2) -> Waypoint:
    var replacement_surface: Surface
    var replacement_position := Vector2.INF
    var should_stay_on_min_side: bool
    
    match fake_waypoint.side:
        SurfaceSide.FLOOR:
            should_stay_on_min_side = false
            
            if fake_waypoint.should_stay_on_min_side:
                # Replacing top-left corner with bottom-left corner.
                
                # In case of a concave neighbor, loop until we find the nearest
                # convex wall.
                var neighbor_surface := \
                        fake_waypoint.surface.counter_clockwise_neighbor
                var iterations := 1
                while iterations < FAKE_REPLACEMENT_SEARCH_MAX_ITERATIONS:
                    if neighbor_surface.side == SurfaceSide.RIGHT_WALL and \
                            neighbor_surface \
                                    .counter_clockwise_convex_neighbor != null:
                        replacement_surface = neighbor_surface
                        replacement_position = neighbor_surface.first_point + \
                                Vector2(-waypoint_offset.x, waypoint_offset.y)
                        break
                    
                    neighbor_surface = \
                            neighbor_surface.counter_clockwise_neighbor
                    iterations += 1
            else:
                # Replacing top-right corner with bottom-right corner.
                
                # In case of a concave neighbor, loop until we find the nearest
                # convex wall.
                var neighbor_surface := \
                        fake_waypoint.surface.clockwise_neighbor
                var iterations := 1
                while iterations < FAKE_REPLACEMENT_SEARCH_MAX_ITERATIONS:
                    if neighbor_surface.side == SurfaceSide.LEFT_WALL and \
                            neighbor_surface.clockwise_convex_neighbor != null:
                        replacement_surface = neighbor_surface
                        replacement_position = neighbor_surface.last_point + \
                                Vector2(waypoint_offset.x, waypoint_offset.y)
                        break
                    
                    neighbor_surface = neighbor_surface.clockwise_neighbor
                    iterations += 1
        
        SurfaceSide.CEILING:
            should_stay_on_min_side = true
            
            if fake_waypoint.should_stay_on_min_side:
                # Replacing bottom-left corner with top-left corner.
                
                # In case of a concave neighbor, loop until we find the nearest
                # convex wall.
                var neighbor_surface := \
                        fake_waypoint.surface.clockwise_neighbor
                var iterations := 1
                while iterations < FAKE_REPLACEMENT_SEARCH_MAX_ITERATIONS:
                    if neighbor_surface.side == SurfaceSide.RIGHT_WALL and \
                            neighbor_surface.clockwise_convex_neighbor != null:
                        replacement_surface = neighbor_surface
                        replacement_position = neighbor_surface.last_point + \
                                Vector2(-waypoint_offset.x, -waypoint_offset.y)
                        break
                    
                    neighbor_surface = neighbor_surface.clockwise_neighbor
                    iterations += 1
            else:
                # Replacing bottom-right corner with top-right corner.
                
                # In case of a concave neighbor, loop until we find the nearest
                # convex wall.
                var neighbor_surface := \
                        fake_waypoint.surface.counter_clockwise_neighbor
                var iterations := 1
                while iterations < FAKE_REPLACEMENT_SEARCH_MAX_ITERATIONS:
                    if neighbor_surface.side == SurfaceSide.LEFT_WALL and \
                            neighbor_surface \
                                    .counter_clockwise_convex_neighbor != null:
                        replacement_surface = neighbor_surface
                        replacement_position = neighbor_surface.first_point + \
                                Vector2(waypoint_offset.x, -waypoint_offset.y)
                        break
                    
                    neighbor_surface = \
                            neighbor_surface.counter_clockwise_neighbor
                    iterations += 1
            
        _:
            Sc.logger.error("WaypointUtils._calculate_replacement_for_fake_waypoint")
    
    if replacement_surface == null:
        # We didn't find a replacement.
        return null
    
    var replacement := Waypoint.new(
            replacement_surface,
            replacement_position,
            false,
            should_stay_on_min_side,
            true,
            fake_waypoint.previous_waypoint,
            fake_waypoint.next_waypoint)
    replacement.replaced_a_fake = true
    return replacement


static func clone_waypoint(original: Waypoint) -> Waypoint:
    var clone := Waypoint.new(
            original.surface,
            original.position,
            original.passing_vertically,
            original.should_stay_on_min_side,
            original.is_at_end_of_surface,
            original.previous_waypoint,
            original.next_waypoint)
    copy_waypoint(clone, original)
    return clone


static func copy_waypoint(
        destination: Waypoint,
        source: Waypoint) -> void:
    destination.surface = source.surface
    destination.position = source.position
    destination.passing_vertically = source.passing_vertically
    destination.should_stay_on_min_side = source.should_stay_on_min_side
    destination.previous_waypoint = source.previous_waypoint
    destination.next_waypoint = source.next_waypoint
    destination.horizontal_movement_sign = source.horizontal_movement_sign
    destination.horizontal_movement_sign_from_displacement = \
            source.horizontal_movement_sign_from_displacement
    destination.time_passing_through = source.time_passing_through
    destination.min_velocity_x = source.min_velocity_x
    destination.max_velocity_x = source.max_velocity_x
    destination.actual_velocity_x = source.actual_velocity_x
    destination.needs_extra_jump_duration = source.needs_extra_jump_duration
    destination.is_origin = source.is_origin
    destination.is_destination = source.is_destination
    destination.is_fake = source.is_fake
    destination.replaced_a_fake = source.replaced_a_fake
    destination.validity = source.validity
