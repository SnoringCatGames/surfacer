# A collection of utility functions for calculating state related to movement.
class_name MovementUtils

# Calculates the duration to reach the destination with the given movement parameters.
#
# - Since we are dealing with a parabolic equation, there are likely two possible results.
#   returns_lower_result indicates whether to return the lower, non-negative result.
# - expects_only_one_positive_result indicates whether to report an error if there are two
#   positive results.
# - Returns INF if we cannot reach the destination with our movement parameters.
static func calculate_movement_duration(displacement: float, v_0: float, a: float, \
        returns_lower_result := true, min_duration := 0.0, \
        expects_only_one_positive_result := false) -> float:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    
    # Use only non-negative results.
    assert(min_duration >= 0)
    
    if displacement == 0 and returns_lower_result and min_duration == 0.0:
        # The start position is the destination.
        return 0.0
    elif a == 0:
        # Handle the degenerate case with no acceleration.
        if v_0 == 0:
            # We can't reach the destination, since we're not moving anywhere.
            return INF 
        elif (displacement > 0) != (v_0 > 0):
            # We can't reach the destination, since we're moving in the wrong direction.
            return INF
        else:
            # s = s_0 + v_0*t
            return displacement / v_0
    
    # From a basic equation of motion:
    #     s = s_0 + v_0*t + 1/2*a*t^2.
    # Solve for t using the quadratic formula.
    var discriminant := v_0 * v_0 + 2 * a * displacement
    if discriminant < 0:
        # We can't reach the end position from our start position.
        return INF
    var discriminant_sqrt := sqrt(discriminant)
    var t1 := (-v_0 + discriminant_sqrt) / a
    var t2 := (-v_0 - discriminant_sqrt) / a
    
    # Optionally ensure that only one result is positive.
    assert(!expects_only_one_positive_result or t1 < 0 or t2 < 0)
    # Ensure that there are not two negative results.
    assert(t1 >= 0 or t2 >= 0)
    
    min_duration += Geometry.FLOAT_EPSILON
    
    if t1 < min_duration:
        if t2 < min_duration:
            return INF
        else:
            return t2
    elif t2 < min_duration:
        if t1 < min_duration:
            return INF
        else:
            return t1
    else:
        if returns_lower_result:
            return min(t1, t2)
        else:
            return max(t1, t2)

# Calculates the duration to accelerate over in order to reach the destination at the given time,
# given that velocity continues after acceleration stops and a new backward acceleration is
# applied.
# 
# Note: This could depend on a speed that exceeds the max-allowed speed.
# FIXME: F: Remove if no-one is still using this.
static func calculate_time_to_release_acceleration(time_start: float, time_step_end: float, \
        position_start: float, position_end: float, velocity_start: float, \
        acceleration_start: float, post_release_backward_acceleration: float, \
        returns_lower_result := true, expects_only_one_positive_result := false) -> float:
    var duration := time_step_end - time_start
    
    # Derivation:
    # - Start with basic equations of motion
    # - v_1 = v_0 + a_0*t_0
    # - s_2 = s_1 + v_1*t_1 + 1/2*a_1*t_1^2
    # - s_0 = s_0 + v_0*t_0 + 1/2*a_0*t_0^2
    # - t_2 = t_0 + t_1
    # - Do some algebra...
    # - 0 = (1/2*(a_0 - a_1)) * t_0^2 + (t_2 * (a_1 - a_0)) * t_0 + (s_2 - s_0 - t_2 * (v_0 + 1/2*a_1*t_2))
    # - Apply quadratic formula to solve for t_0.
    var a := 0.5 * (acceleration_start - post_release_backward_acceleration)
    var b := duration * (post_release_backward_acceleration - acceleration_start)
    var c := position_end - position_start - duration * \
            (velocity_start + 0.5 * post_release_backward_acceleration * duration)
    
    # This would produce a divide-by-zero.
    assert(a != 0)
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # We can't reach the end position from our start position.
        return INF
    var discriminant_sqrt := sqrt(discriminant)
    var t1 := (-b + discriminant_sqrt) / 2.0 / a
    var t2 := (-b - discriminant_sqrt) / 2.0 / a
    
    # Optionally ensure that only one result is positive.
    assert(!expects_only_one_positive_result or t1 < 0 or t2 < 0)
    # Ensure that there are not two negative results.
    assert(t1 >= 0 or t2 >= 0)
    
    # Use only non-negative results.
    if t1 < 0:
        return t2
    elif t2 < 0:
        return t1
    else:
        if returns_lower_result:
            return min(t1, t2)
        else:
            return max(t1, t2)

# Calculates the minimum required time to reach the displacement, considering a maximum velocity.
static func calculate_min_time_to_reach_displacement(displacement: float, v_0: float, \
        speed_max: float, a: float) -> float:
    if displacement == 0.0:
        # The start position is the destination.
        return 0.0
    elif a == 0:
        # Handle the degenerate case with no acceleration.
        if v_0 == 0:
            # We can't reach the destination, since we're not moving anywhere.
            return INF 
        elif (displacement > 0) != (v_0 > 0):
            # We can't reach the destination, since we're moving in the wrong direction.
            return INF
        else:
            # s = s_0 + v_0*t
            return displacement / v_0
    
    var velocity_limit := speed_max if a > 0 else -speed_max
    
    var duration_to_reach_position_with_no_velocity_cap: float = \
            calculate_movement_duration(displacement, v_0, a, true, 0.0, true)
    
    if duration_to_reach_position_with_no_velocity_cap == INF:
        # We can't ever reach the destination.
        return INF
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var duration_to_reach_velocity_limit := (velocity_limit - v_0) / a
    assert(duration_to_reach_velocity_limit >= 0)
    
    if duration_to_reach_velocity_limit >= duration_to_reach_position_with_no_velocity_cap:
        # We won't have hit the max velocity before reaching the destination.
        return duration_to_reach_position_with_no_velocity_cap
    else:
        # We will have hit the max velocity before reaching the destination.
        
        # From a basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        var position_when_reaching_max_velocity := v_0 * duration_to_reach_velocity_limit + \
                0.5 * a * duration_to_reach_velocity_limit * duration_to_reach_velocity_limit
        
        # From a basic equation of motion:
        #     s = s_0 + v*t
        var duration_with_max_velocity := \
                (displacement - position_when_reaching_max_velocity) / velocity_limit
        assert(duration_with_max_velocity > 0)
        
        return duration_to_reach_velocity_limit + duration_with_max_velocity

# Returns up to three points along the given surface for jumping-from or landing-to, considering
# the given vertices of another nearby surface.
# 
# -   The three possible points are:
#     -   The near end of the surface.
#     -   The far end of the surface.
#     -   The closest point along the surface.
# -   Points are only included if they are distinct.
# -   Points are returned in sorted order: closest, near, far.
static func get_all_jump_positions_from_surface(movement_params: MovementParams, \
        source_surface: Surface, target_vertices: PoolVector2Array, target_bounding_box: Rect2, \
        target_side: int) -> Array:
    var source_first_point := source_surface.first_point
    var source_last_point := source_surface.last_point
    
    # Use a bounding-box heuristic to determine which end of the surfaces are likely to be
    # nearer and farther.
    var near_end: Vector2
    var far_end: Vector2
    if Geometry.distance_squared_from_point_to_rect(source_first_point, target_bounding_box) < \
            Geometry.distance_squared_from_point_to_rect(source_last_point, target_bounding_box):
        near_end = source_first_point
        far_end = source_last_point
    else:
        near_end = source_last_point
        far_end = source_first_point
    
    # Record the near-end point.
    var jump_position := create_position_from_target_point( \
            near_end, source_surface, movement_params.collider_half_width_height)
    var possible_jump_positions = [jump_position]
    
    # Only consider the far-end point if it is distinct.
    if source_surface.vertices.size() > 1:
        jump_position = create_position_from_target_point( \
                far_end, source_surface, movement_params.collider_half_width_height)
        possible_jump_positions.push_back(jump_position)
        
        var source_surface_center := source_surface.bounding_box.position + \
                (source_surface.bounding_box.end - source_surface.bounding_box.position) / 2.0
        var target_surface_center := target_bounding_box.position + \
                (target_bounding_box.end - target_bounding_box.position) / 2.0
        var target_first_point := target_vertices[0]
        var target_last_point := target_vertices[target_vertices.size() - 1]
        
        var horizontal_offset := movement_params.collider_half_width_height.x + \
                MovementCalcOverallParams.EDGE_MOVEMENT_ACTUAL_MARGIN
        
        # Instead of choosing the exact closest point along the source surface to the target
        # surface, we may want to give the "closest" jump-off point an offset that should reduce
        # overall movement.
        # 
        # As an example of when this offset is important, consider the case when we jump from floor
        # surface A to floor surface B, which lies exactly above A. In this case, the jump movement
        # must go around one edge of B or the other in order to land on the top-side of B. Ideally,
        # the jump position from A would already be outside the edge of B, so that we don't need to
        # first move horizontally outward and then back in. However, the exact "closest" point on A
        # to B will not be outside the edge of B.
        var closest_point_on_source := Vector2.INF
        if source_surface.side == SurfaceSide.FLOOR:
            if source_surface_center.y < target_surface_center.y:
                # Source surface is above target surface.
                
                # closest_point_on_source must be one of the ends of the source surface.
                closest_point_on_source = source_last_point if \
                        source_surface_center.x < target_surface_center.x else \
                        source_first_point
            else:
                # Source surface is below target surface.
                
                if target_side == SurfaceSide.FLOOR:
                    # Choose whichever target end point is closer to the source center, and
                    # calculate a half-player-width offset from there.
                    var should_try_to_move_around_left_side_of_target := \
                            abs(target_first_point.x - source_surface_center.x) < \
                            abs(target_last_point.x - source_surface_center.x)
                    var closest_point_on_target: Vector2
                    var goal_x_on_source: float
                    if should_try_to_move_around_left_side_of_target:
                        closest_point_on_target = target_first_point
                        goal_x_on_source = closest_point_on_target.x - horizontal_offset
                    else:
                        closest_point_on_target = target_last_point
                        goal_x_on_source = closest_point_on_target.x + horizontal_offset
                    
                    # Calculate the closest point on the source surface to our goal offset point.
                    closest_point_on_source = Geometry.project_point_onto_surface( \
                            Vector2(goal_x_on_source, INF), source_surface)
                elif target_side == SurfaceSide.LEFT_WALL or target_side == SurfaceSide.RIGHT_WALL:
                    # Find the point along the target surface that's closest to the source center,
                    # and calculate a half-player-width offset from there.
                    var closest_point_on_target: Vector2 = \
                            Geometry.get_closest_point_on_polyline_to_polyline( \
                                    target_vertices, source_surface.vertices)
                    var goal_x_on_source := closest_point_on_target.x + \
                            (horizontal_offset if target_side == SurfaceSide.LEFT_WALL else \
                            -horizontal_offset)
                    
                    # Calculate the closest point on the source surface to our goal offset point.
                    closest_point_on_source = Geometry.project_point_onto_surface( \
                            Vector2(goal_x_on_source, INF), source_surface)
                else: # target_side == SurfaceSide.CEILING
                    # We can use any point along the target surface.
                    closest_point_on_source = Geometry.get_closest_point_on_polyline_to_polyline( \
                            source_surface.vertices, target_vertices)
        elif source_surface.side == SurfaceSide.LEFT_WALL or \
                source_surface.side == SurfaceSide.RIGHT_WALL:
            # FIXME: --------------
            pass
        else: # source_surface.side == SurfaceSide.CEILING
            # FIXME: --------------
            pass
        
        # FIXME: --------------- REMOVE
        if closest_point_on_source == Vector2.INF:
            closest_point_on_source = Geometry.get_closest_point_on_polyline_to_polyline( \
                    source_surface.vertices, target_vertices)
        
        
        
        # Only consider the closest point if it is distinct.
        if closest_point_on_source != near_end and closest_point_on_source != far_end:
            jump_position = create_position_from_target_point( \
                    closest_point_on_source, source_surface, movement_params.collider_half_width_height)
            possible_jump_positions.push_front(jump_position)
    
    return possible_jump_positions

static func create_position_from_target_point(target_point: Vector2, surface: Surface, \
        collider_half_width_height: Vector2) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    position.match_surface_target_and_collider(surface, target_point, collider_half_width_height)
    return position

static func update_velocity_in_air( \
        velocity: Vector2, delta: float, is_pressing_jump: bool, is_first_jump: bool, \
        horizontal_acceleration_sign: int, movement_params: MovementParams) -> Vector2:
    var is_ascending_from_jump := velocity.y < 0 and is_pressing_jump
    
    # Make gravity stronger when falling. This creates a more satisfying jump.
    # Similarly, make gravity stronger for double jumps.
    var gravity_multiplier := 1.0 if !is_ascending_from_jump else \
            (movement_params.slow_ascent_gravity_multiplier if is_first_jump \
                    else movement_params.ascent_double_jump_gravity_multiplier)
    
    # Vertical movement.
    velocity.y += delta * movement_params.gravity_fast_fall * gravity_multiplier
    
    # Horizontal movement.
    velocity.x += delta * movement_params.in_air_horizontal_acceleration * horizontal_acceleration_sign
    
    return velocity

static func cap_velocity(velocity: Vector2, movement_params: MovementParams, \
        current_max_horizontal_speed: float) -> Vector2:
    # Cap horizontal speed at a max value.
    velocity.x = clamp(velocity.x, -current_max_horizontal_speed, current_max_horizontal_speed)
    
    # Kill horizontal speed below a min value.
    if velocity.x > -movement_params.min_horizontal_speed and \
            velocity.x < movement_params.min_horizontal_speed:
        velocity.x = 0
    
    # Cap vertical speed at a max value.
    velocity.y = clamp(velocity.y, -movement_params.max_vertical_speed, \
            movement_params.max_vertical_speed)
    
    # Kill vertical speed below a min value.
    if velocity.y > -movement_params.min_vertical_speed and \
            velocity.y < movement_params.min_vertical_speed:
        velocity.y = 0
    
    return velocity
