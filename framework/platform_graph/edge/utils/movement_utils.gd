# A collection of utility functions for calculating state related to movement.
class_name MovementUtils

const EXTRA_JUMP_LAND_POSITION_MARGIN := 2.0
const MAX_VELOCITY_HORIZONTAL_OFFSET_SUBTRACT_PLAYER_WIDTH_RATIO := 0.6

# Calculates the duration to reach the destination with the given movement parameters.
#
# - Since we are dealing with a parabolic equation, there are likely two possible results.
#   returns_lower_result indicates whether to return the lower, non-negative result.
# - expects_only_one_positive_result indicates whether to report an error if there are two
#   positive results.
# - Returns INF if we cannot reach the destination with our movement parameters.
static func calculate_movement_duration(displacement: float, v_0: float, a: float, \
        returns_lower_result := true, min_duration := 0.0, \
        expects_only_one_positive_result := false, allows_no_positive_results := false) -> float:
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
    
    # Check for two negative results.
    if t1 < 0 and t2 < 0:
        assert(allows_no_positive_results)
        return INF
    
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
static func calculate_time_for_displacement(displacement: float, velocity_start: float, \
        acceleration: float, max_speed: float) -> float:
    if displacement == 0.0:
        # The start position is the destination.
        return 0.0
    elif acceleration == 0.0:
        # Handle the degenerate case with no acceleration.
        if velocity_start == 0.0:
            # We can't reach the destination, since we're not moving anywhere.
            return INF 
        elif (displacement > 0.0) != (velocity_start > 0.0):
            # We can't reach the destination, since we're moving in the wrong direction.
            return INF
        else:
            # s = s_0 + v_0*t
            return displacement / velocity_start
    
    var velocity_at_max_speed := max_speed if displacement > 0.0 else -max_speed
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    # Algebra...
    #     t = (v - v_0) / a
    var time_to_reach_max_speed := \
            (velocity_at_max_speed - velocity_start) / acceleration
    if time_to_reach_max_speed < 0.0:
        # We're accelerating in the wrong direction.
        return INF
    
    # From a basic equation of motion:
    #     s = s_0 + v_0*t + 1/2*a*t^2
    # Algebra...
    #     (s - s_0) = v_0*t + 1/2*a*t^2
    var displacement_to_reach_max_speed := \
            velocity_start * time_to_reach_max_speed + \
            0.5 * acceleration * time_to_reach_max_speed * \
            time_to_reach_max_speed
    
    if displacement_to_reach_max_speed > displacement and displacement > 0.0 or \
            displacement_to_reach_max_speed < displacement and displacement < 0.0:
        # We do not reach max speed before we reach the displacement.
        return calculate_movement_duration( \
                displacement, velocity_start, acceleration, true, 0.0, true)
    else:
        # We reach max speed before we reach the displacement.
        
        var remaining_displacement_at_max_speed := displacement - displacement_to_reach_max_speed
        # From a basic equation of motion:
        #     s = s_0 + v*t
        # Algebra...
        #     t = (s - s_0) / v
        var remaining_time_at_max_speed := \
                remaining_displacement_at_max_speed / velocity_at_max_speed
        
        return time_to_reach_max_speed + remaining_time_at_max_speed

static func calculate_velocity_end_for_displacement(displacement: float, velocity_start: float, \
        acceleration: float, max_speed: float) -> float:
    if displacement == 0.0:
        # The start position is the destination.
        return velocity_start
    elif acceleration == 0.0:
        # Handle the degenerate case with no acceleration.
        if velocity_start == 0.0:
            # We can't reach the destination, since we're not moving anywhere.
            return INF 
        elif (displacement > 0.0) != (velocity_start > 0.0):
            # We can't reach the destination, since we're moving in the wrong direction.
            return INF
        else:
            # s = s_0 + v_0*t
            return displacement / velocity_start
    
    var velocity_at_max_speed := max_speed if displacement > 0.0 else -max_speed
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    # Algebra...
    #     t = (v - v_0) / a
    var time_to_reach_max_speed := \
            (velocity_at_max_speed - velocity_start) / acceleration
    if time_to_reach_max_speed < 0.0:
        # We're accelerating in the wrong direction.
        return INF
    
    # From a basic equation of motion:
    #     s = s_0 + v_0*t + 1/2*a*t^2
    # Algebra...
    #     (s - s_0) = v_0*t + 1/2*a*t^2
    var displacement_to_reach_max_speed := \
            velocity_start * time_to_reach_max_speed + \
            0.5 * acceleration * time_to_reach_max_speed * \
            time_to_reach_max_speed
    
    if displacement_to_reach_max_speed > displacement and displacement > 0.0 or \
            displacement_to_reach_max_speed < displacement and displacement < 0.0:
        # We do not reach max speed before we reach the displacement.
        
        var time_for_displacement := calculate_movement_duration( \
                displacement, velocity_start, acceleration, true, 0.0, true)
        
        # From a basic equation of motion:
        #     v = v_0 + a*t
        return velocity_start + acceleration * time_for_displacement
    else:
        # We reach max speed before we reach the displacement.
        return velocity_at_max_speed

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
static func get_all_jump_land_positions_for_surface(movement_params: MovementParams, \
        surface: Surface, other_surface_vertices: PoolVector2Array, \
        other_surface_bounding_box: Rect2, other_surface_side: int, velocity_start_y: float, \
        is_jump_off_surface: bool) -> Array:
    var surface_first_point := surface.first_point
    var surface_last_point := surface.last_point
    
    # Use a bounding-box heuristic to determine which end of the surfaces are likely to be
    # nearer and farther.
    var near_end := Vector2.INF
    var far_end := Vector2.INF
    if Geometry.distance_squared_from_point_to_rect( \
            surface_first_point, other_surface_bounding_box) < \
            Geometry.distance_squared_from_point_to_rect( \
                    surface_last_point, other_surface_bounding_box):
        near_end = surface_first_point
        far_end = surface_last_point
    else:
        near_end = surface_last_point
        far_end = surface_first_point
    
    # Record the near-end point.
    var jump_position := create_position_offset_from_target_point( \
            near_end, surface, movement_params.collider_half_width_height)
    var possible_jump_positions := [jump_position]
    
    # Only consider the far-end point if it is distinct.
    if surface.vertices.size() > 1:
        jump_position = create_position_offset_from_target_point( \
                far_end, surface, movement_params.collider_half_width_height)
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
                            Vector2(goal_x_on_surface, INF), surface)
                    
                elif other_surface_side == SurfaceSide.LEFT_WALL or \
                        other_surface_side == SurfaceSide.RIGHT_WALL:
                    should_try_to_move_around_left_side_of_target = \
                            other_surface_side == SurfaceSide.LEFT_WALL
                    # Find the point along the other surface that's closest to the source surface,
                    # and calculate a half-player-width offset from there.
                    closest_point_on_other_surface = \
                            Geometry.get_closest_point_on_polyline_to_polyline( \
                                    other_surface_vertices, surface.vertices)
                    goal_x_on_surface = closest_point_on_other_surface.x + \
                            (player_width_horizontal_offset if \
                            other_surface_side == SurfaceSide.LEFT_WALL else \
                            -player_width_horizontal_offset)
                    # Calculate the "closest" point on the source surface to our goal offset point.
                    closest_point_on_surface = Geometry.project_point_onto_surface( \
                            Vector2(goal_x_on_surface, INF), surface)
                    
                else: # other_surface_side == SurfaceSide.CEILING
                    # We can use any point along the other surface.
                    closest_point_on_surface = \
                            Geometry.get_closest_point_on_polyline_to_polyline( \
                                    surface.vertices, other_surface_vertices)
                
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
                    var fall_time_with_max_gravity := calculate_time_for_displacement( \
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
                            Vector2(goal_x_on_surface, INF), surface)
            
        elif surface.side == SurfaceSide.LEFT_WALL or \
                surface.side == SurfaceSide.RIGHT_WALL:
            # FIXME: -------------- LEFT OFF HERE
            # FIXME: -------------- REMOVE
            closest_point_on_surface = \
                    Geometry.get_closest_point_on_polyline_to_polyline( \
                            surface.vertices, other_surface_vertices)
            
        else: # surface.side == SurfaceSide.CEILING
            # FIXME: -------------- LEFT OFF HERE
            # FIXME: -------------- REMOVE
            closest_point_on_surface = \
                    Geometry.get_closest_point_on_polyline_to_polyline( \
                            surface.vertices, other_surface_vertices)
        
        # Only consider the horizontal-movement point if it is distinct.
        if movement_params.considers_mid_point_matching_horizontal_movement_for_jump_land_position and \
                mid_point_matching_horizontal_movement != Vector2.INF and \
                mid_point_matching_horizontal_movement != near_end and \
                mid_point_matching_horizontal_movement != far_end and \
                mid_point_matching_horizontal_movement != closest_point_on_surface:
            jump_position = create_position_offset_from_target_point( \
                    mid_point_matching_horizontal_movement, surface, \
                    movement_params.collider_half_width_height)
            possible_jump_positions.push_front(jump_position)
        
        # Only consider the "closest" point if it is distinct.
        if movement_params.considers_closest_mid_point_for_jump_land_position and \
                closest_point_on_surface != Vector2.INF and \
                closest_point_on_surface != near_end and \
                closest_point_on_surface != far_end:
            jump_position = create_position_offset_from_target_point( \
                    closest_point_on_surface, surface, \
                    movement_params.collider_half_width_height)
            possible_jump_positions.push_front(jump_position)
    
    return possible_jump_positions

static func create_position_offset_from_target_point(target_point: Vector2, surface: Surface, \
        collider_half_width_height: Vector2, \
        clips_to_surface_bounds := false) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    position.match_surface_target_and_collider(surface, target_point, collider_half_width_height, \
            true, clips_to_surface_bounds)
    return position

static func create_position_from_target_point(target_point: Vector2, surface: Surface, \
        collider_half_width_height: Vector2, offsets_target_by_half_width_height := false, \
        clips_to_surface_bounds := false) -> PositionAlongSurface:
    assert(surface != null)
    var position := PositionAlongSurface.new()
    position.match_surface_target_and_collider(surface, target_point, collider_half_width_height, \
            offsets_target_by_half_width_height, clips_to_surface_bounds)
    return position

static func create_position_without_surface(target_point: Vector2) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    position.target_point = target_point
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

static func calculate_time_to_climb(distance: float, is_climbing_upward: bool, \
        movement_params: MovementParams) -> float:
    var speed := movement_params.climb_up_speed if is_climbing_upward else \
            movement_params.climb_down_speed
    # From a basic equation of motion:
    #     s = s_0 + v*t
    # Algebra...
    #     t = (s - s_0) / v
    return distance / speed

static func calculate_time_to_walk(distance: float, v_0: float, \
        movement_params: MovementParams) -> float:
    return calculate_time_for_displacement(distance, v_0, \
            movement_params.walk_acceleration, movement_params.max_horizontal_speed_default)
