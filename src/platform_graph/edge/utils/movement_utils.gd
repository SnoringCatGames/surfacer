class_name MovementUtils
extends Reference
## A collection of utility functions for calculating state related to movement.


## Calculates the duration to reach the destination with the given movement
## parameters.
##
## -   Since we are dealing with a parabolic equation, there are likely two
##     possible results. returns_lower_result indicates whether to return the
##     lower, non-negative result.
## -   expects_only_one_positive_result indicates whether to report an error if
##     there are two positive results.
## -   Returns INF if we cannot reach the destination with our movement
##     parameters.
static func calculate_movement_duration(
        displacement: float,
        v_0: float,
        a: float,
        returns_lower_result := true,
        min_duration := 0.0,
        expects_only_one_positive_result := false,
        allows_no_positive_results := false) -> float:
    # FIXME: Account for max y velocity when calculating any parabolic motion.
    
    # Use only non-negative results.
    assert(min_duration >= 0.0)
    
    if displacement == 0.0 and \
            (returns_lower_result or \
            expects_only_one_positive_result) and \
            min_duration == 0.0:
        # The start position is the destination.
        return 0.0
    elif a == 0.0:
        # Handle the degenerate case with no acceleration.
        if v_0 == 0.0:
            # We can't reach the destination, since we're not moving anywhere.
            return INF
        elif (displacement > 0.0) != (v_0 > 0.0):
            # We can't reach the destination, since we're moving in the wrong
            # direction.
            return INF
        else:
            # s = s_0 + v_0*t
            var duration := displacement / v_0
            
            return duration if duration > 0.0 else INF
    
    # From a basic equation of motion:
    #     s = s_0 + v_0*t + 1/2*a*t^2
    # Solve for t using the quadratic formula.
    var discriminant := v_0 * v_0 + 2.0 * a * displacement
    if discriminant < 0.0:
        # We can't reach the end position from our start position.
        return INF
    var discriminant_sqrt := sqrt(discriminant)
    var t1 := (-v_0 + discriminant_sqrt) / a
    var t2 := (-v_0 - discriminant_sqrt) / a
    
    # Optionally ensure that only one result is positive.
    assert(!expects_only_one_positive_result or t1 < 0.0 or t2 < 0.0)
    
    # Check for two negative results.
    if t1 < 0.0 and t2 < 0.0:
        assert(allows_no_positive_results)
        return INF
    
    # This epsilon is important for calculations that depend on the result
    # actually happening within expected values, but for calculations that just
    # expect any value over 0.0, we don't need the epsilon.
    if min_duration != 0.0:
        min_duration += Sc.geometry.FLOAT_EPSILON
    
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


## Calculates the duration to accelerate over in order to reach the destination
## at the given time, given that velocity continues after acceleration stops and
## a new backward acceleration is applied.
## 
## Note: This could depend on a speed that exceeds the max-allowed speed.
# FIXME: Remove if no-one is still using this.
static func calculate_time_to_release_acceleration(
        time_start: float,
        time_step_end: float,
        position_start: float,
        position_end: float,
        velocity_start: float,
        acceleration_start: float,
        post_release_backward_acceleration: float,
        returns_lower_result := true,
        expects_only_one_positive_result := false) -> float:
    var duration := time_step_end - time_start
    
    # Derivation:
    # - Start with basic equations of motion
    # - v_1 = v_0 + a_0*t_0
    # - s_2 = s_1 + v_1*t_1 + 1/2*a_1*t_1^2
    # - s_0 = s_0 + v_0*t_0 + 1/2*a_0*t_0^2
    # - t_2 = t_0 + t_1
    # - Do some algebra...
    # - 0 = (1/2*(a_0 - a_1)) * t_0^2 + (t_2 * (a_1 - a_0)) * t_0 + 
    #       (s_2 - s_0 - t_2 * (v_0 + 1/2*a_1*t_2))
    # - Apply quadratic formula to solve for t_0.
    var a := 0.5 * (acceleration_start - post_release_backward_acceleration)
    var b := duration * \
            (post_release_backward_acceleration - acceleration_start)
    var c := position_end - position_start - duration * \
            (velocity_start + \
                    0.5 * post_release_backward_acceleration * duration)
    
    # This would produce a divide-by-zero.
    assert(a != 0.0)
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0.0:
        # We can't reach the end position from our start position.
        return INF
    var discriminant_sqrt := sqrt(discriminant)
    var t1 := (-b + discriminant_sqrt) / 2.0 / a
    var t2 := (-b - discriminant_sqrt) / 2.0 / a
    
    # Optionally ensure that only one result is positive.
    assert(!expects_only_one_positive_result or t1 < 0.0 or t2 < 0.0)
    # Ensure that there are not two negative results.
    assert(t1 >= 0 or t2 >= 0.0)
    
    # Use only non-negative results.
    if t1 < 0.0:
        return t2
    elif t2 < 0.0:
        return t1
    else:
        if returns_lower_result:
            return min(t1, t2)
        else:
            return max(t1, t2)


## Calculates the minimum required duration to reach the displacement,
## considering a maximum velocity.
static func calculate_duration_for_displacement(
        displacement: float,
        velocity_start: float,
        acceleration: float,
        max_speed: float,
        returns_lower_result := true) -> float:
    if displacement == 0.0:
        # The start position is the destination.
        return 0.0
    elif acceleration == 0.0:
        # Handle the degenerate case with no acceleration.
        if velocity_start == 0.0:
            # We can't reach the destination, since we're not moving anywhere.
            return INF
        elif (displacement > 0.0) != (velocity_start > 0.0):
            # We can't reach the destination, since we're moving in the wrong
            # direction.
            return INF
        else:
            # s = s_0 + v_0*t
            var duration := displacement / velocity_start
            
            return duration if \
                    duration >= 0.0 else \
                    INF
    
    var velocity_at_max_speed := \
            max_speed if \
            acceleration > 0.0 else \
            -max_speed
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    # Algebra...
    #     t = (v - v_0) / a
    var time_to_reach_max_speed := \
            (velocity_at_max_speed - velocity_start) / acceleration
    
    var time_to_reach_destination_without_speed_cap := \
            calculate_movement_duration(
                displacement,
                velocity_start,
                acceleration,
                returns_lower_result,
                0.0,
                false,
                false)
    
    var reaches_destination_before_max_speed := \
            time_to_reach_destination_without_speed_cap <= \
            time_to_reach_max_speed
    
    if reaches_destination_before_max_speed:
        # We do not reach max speed before we reach the displacement.
        return time_to_reach_destination_without_speed_cap
    else:
        # We reach max speed before we reach the displacement.
        
        # From a basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        # Algebra...
        #     (s - s_0) = v_0*t + 1/2*a*t^2
        var displacement_to_reach_max_speed := \
                velocity_start * time_to_reach_max_speed + \
                0.5 * acceleration * \
                time_to_reach_max_speed * time_to_reach_max_speed
        var remaining_displacement_at_max_speed := \
                displacement - displacement_to_reach_max_speed
        # From a basic equation of motion:
        #     s = s_0 + v*t
        # Algebra...
        #     t = (s - s_0) / v
        var remaining_time_at_max_speed := \
                remaining_displacement_at_max_speed / velocity_at_max_speed
        
        var duration := time_to_reach_max_speed + remaining_time_at_max_speed
        
        return duration if duration > 0.0 else INF


static func calculate_velocity_end_for_displacement(
        displacement: float,
        velocity_start: float,
        acceleration: float,
        max_speed: float,
        returns_lower_result := true,
        should_clamp_velocity_to_max_speed := false) -> float:
    if should_clamp_velocity_to_max_speed:
        velocity_start = clamp(velocity_start, -max_speed, max_speed)
    else:
        assert(abs(velocity_start) <= max_speed)
    
    if displacement == 0.0:
        # The start position is the destination.
        return velocity_start
    elif acceleration == 0.0:
        # Handle the degenerate case with no acceleration.
        if velocity_start == 0.0:
            # We can't reach the destination, since we're not moving anywhere.
            return INF
        elif (displacement > 0.0) != (velocity_start > 0.0):
            # We can't reach the destination, since we're moving in the wrong
            # direction.
            return INF
        else:
            # s = s_0 + v_0*t
            return displacement / velocity_start
    
    var velocity_at_max_speed := \
            max_speed if \
            acceleration > 0.0 else \
            -max_speed
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    # Algebra...
    #     t = (v - v_0) / a
    var time_to_reach_max_speed := \
            (velocity_at_max_speed - velocity_start) / acceleration
    
    var time_to_reach_destination_without_speed_cap := \
            calculate_movement_duration(
                displacement,
                velocity_start,
                acceleration,
                returns_lower_result,
                0.0,
                false,
                false)
    
    var reaches_destination_before_max_speed := \
            time_to_reach_destination_without_speed_cap <= \
            time_to_reach_max_speed
    
    if reaches_destination_before_max_speed:
        # We do not reach max speed before we reach the displacement.
        # From a basic equation of motion:
        #     v = v_0 + a*t
        return velocity_start + \
                acceleration * time_to_reach_destination_without_speed_cap
    else:
        # We reach max speed before we reach the displacement.
        return velocity_at_max_speed


static func calculate_displacement_for_duration(
        duration: float,
        velocity_start: float,
        acceleration: float,
        max_speed: float) -> float:
    assert(duration >= 0.0)
    
    if duration == 0.0:
        return 0.0
    
    if acceleration == 0.0:
        # From a basic equation of motion:
        #     s = s_0 + v*t
        # Algebra...:
        #     (s - s_0) = v*t
        return velocity_start * duration
    
    var velocity_terminal := \
            max_speed if \
            acceleration > 0.0 else \
            -max_speed
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    # Algebra...:
    #     t = (v - v_0) / a
    var time_to_max_speed := \
            (velocity_terminal - velocity_start) / acceleration
    
    if time_to_max_speed > duration:
        # The motion consists of constant acceleration over the entire
        # interval.
        
        # From a basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        # Algebra...:
        #     (s - s_0) = v_0*t + 1/2*a*t^2
        return velocity_start * duration + \
                0.5 * acceleration * duration * duration
    else:
        # The motion consists of two parts:
        # 1.  Constant acceleration until reaching max speed.
        # 2.  Constant velocity at max speed for the remaining duration.
        
        # From a basic equation of motion:
        #     v^2 = v_0^2 + 2*a*(s - s0)
        # Algebra...:
        #     (s - s_0) = (v^2 - v_0^2) / 2 / a
        var displacement_during_acceleration := \
                (velocity_terminal * velocity_terminal - \
                        velocity_start * velocity_start) / \
                2.0 / acceleration
        
        # From a basic equation of motion:
        #     s = s_0 + v*t
        # Algebra...:
        #     (s - s_0) = v*t
        var displacement_at_max_speed := \
                velocity_terminal * (duration - time_to_max_speed)
        
        return displacement_during_acceleration + displacement_at_max_speed


static func update_velocity_in_air(
        velocity: Vector2,
        delta: float,
        is_pressing_jump: bool,
        is_first_jump: bool,
        horizontal_acceleration_sign: int,
        movement_params: MovementParameters) -> Vector2:
    var is_rising_from_jump := velocity.y < 0 and is_pressing_jump
    
    # Make gravity stronger when falling. This creates a more satisfying jump.
    # Similarly, make gravity stronger for double jumps.
    var gravity := \
            movement_params.gravity_fast_fall if \
            !is_rising_from_jump else \
            (movement_params.gravity_slow_rise if \
            is_first_jump else \
            movement_params.rise_double_jump_gravity)
    
    # Vertical movement.
    velocity.y += \
            delta * \
            gravity
    
    # Horizontal movement.
    velocity.x += \
            delta * \
            movement_params.in_air_horizontal_acceleration * \
            horizontal_acceleration_sign
    
    return velocity


static func cap_velocity(
        velocity: Vector2,
        movement_params: MovementParameters,
        current_max_horizontal_speed: float) -> Vector2:
    # Cap horizontal speed at a max value.
    velocity.x = clamp(
            velocity.x,
            -current_max_horizontal_speed,
            current_max_horizontal_speed)
    
    # Kill horizontal speed below a min value.
    if velocity.x > -Su.movement.min_horizontal_speed and \
            velocity.x < Su.movement.min_horizontal_speed:
        velocity.x = 0
    
    # Cap vertical speed at a max value.
    velocity.y = clamp(
            velocity.y,
            -movement_params.max_vertical_speed,
            movement_params.max_vertical_speed)
    
    # Kill vertical speed below a min value.
    if velocity.y > -Su.movement.min_vertical_speed and \
            velocity.y < Su.movement.min_vertical_speed:
        velocity.y = 0
    
    return velocity


static func calculate_time_to_climb(
        distance: float,
        is_climbing_upward: bool,
        surface: Surface,
        movement_params: MovementParameters) -> float:
    var speed := \
            movement_params.climb_up_speed if \
            is_climbing_upward else \
            movement_params.climb_down_speed
    speed *= surface.properties.speed_multiplier
    # From a basic equation of motion:
    #     s = s_0 + v*t
    # Algebra...
    #     t = (s - s_0) / v
    return abs(distance / speed)


static func calculate_time_to_crawl_on_ceiling(
        distance: float,
        surface: Surface,
        movement_params: MovementParameters) -> float:
    # From a basic equation of motion:
    #     s = s_0 + v*t
    # Algebra...
    #     t = (s - s_0) / v
    return abs(distance / (movement_params.ceiling_crawl_speed * \
            surface.properties.speed_multiplier))


# NOTE: Keep this logic in-sync with FloorFrictionAction.
static func get_walking_acceleration_with_friction_magnitude(
        movement_params: MovementParameters,
        surface_properties: SurfaceProperties) -> float:
    var friction_factor := \
            movement_params.friction_coeff_with_sideways_input * \
            surface_properties.friction_multiplier
    var walk_acceleration_with_surface_properties := \
            movement_params.walk_acceleration * \
            surface_properties.speed_multiplier
    var walk_acceleration_with_friction := \
            walk_acceleration_with_surface_properties * \
            (1 - 1 / (friction_factor + 1.0))
    return clamp(
            walk_acceleration_with_friction,
            0.0,
            walk_acceleration_with_surface_properties)


# NOTE: Keep this logic in-sync with FloorFrictionAction.
static func get_stopping_friction_acceleration_magnitude(
        movement_params: MovementParameters,
        surface_properties: SurfaceProperties) -> float:
    return movement_params.friction_coeff_without_sideways_input * \
            movement_params.gravity_fast_fall * \
            surface_properties.friction_multiplier


static func calculate_distance_to_stop_from_friction(
        movement_params: MovementParameters,
        surface_properties: SurfaceProperties,
        velocity_x_start: float) -> float:
    var friction_deceleration := get_stopping_friction_acceleration_magnitude(
            movement_params,
            surface_properties)
    # From a basic equation of motion:
    #     v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
    #     v_1 = 0
    #     s_0 = 0
    # Algebra...:
    #     s_1 = (v_1^2 - v_0^2) / 2 / a
    return abs(-velocity_x_start * velocity_x_start / 2.0 / \
            friction_deceleration)


static func calculate_distance_to_stop_from_friction_with_forward_acceleration_to_non_max_speed(
        movement_params: MovementParameters,
        surface_properties: SurfaceProperties,
        velocity_x_start: float,
        displacement_x_from_end: float) -> float:
    var distance_from_end := abs(displacement_x_from_end)
    
    var max_horizontal_speed := \
            movement_params.get_max_surface_speed() * \
            surface_properties.speed_multiplier
    
    var walk_acceleration := get_walking_acceleration_with_friction_magnitude(
            movement_params,
            surface_properties)
    
    # From a basic equation of motion:
    #     v^2 = v_0^2 + 2*a*(s - s_0)
    # Algebra...:
    #     (s - s_0) = (v^2 - v_0^2) / 2 / a
    var distance_to_max_horizontal_speed := \
            (max_horizontal_speed * max_horizontal_speed - \
            velocity_x_start * velocity_x_start) / \
            2.0 / walk_acceleration
    
    var stopping_distance_from_max_speed := \
            calculate_distance_to_stop_from_friction(
                movement_params,
                surface_properties,
                max_horizontal_speed)
    
    var is_there_enough_room_to_slow_from_max_speed := \
            distance_from_end > \
            distance_to_max_horizontal_speed + \
            stopping_distance_from_max_speed
    
    if is_there_enough_room_to_slow_from_max_speed:
        # There is enough distance to both get to max speed and then slow to a
        # stop from max speed.
        return stopping_distance_from_max_speed
    
    ### We need to calculate stopping distance from a speed that's less than
    ### the max.
    
    var friction_deceleration := get_stopping_friction_acceleration_magnitude(
            movement_params,
            surface_properties)
    if displacement_x_from_end > 0.0:
        friction_deceleration *= -1.0
    else:
        walk_acceleration *= -1.0
    
    # There are two parts of the motion:
    # 1.  Constant acceleration from pressing forward.
    # 2.  Constant deceleration from friction.
    # We can use this to calculate the distance of either part.
    # 
    # From basic equations of motion:
    #     v_1^2 = v_0^2 + 2*a_0*(s_1 - s_0)
    #     v_2^2 = v_1^2 + 2*a_1*(s_2 - s_1)
    #     s_0 = 0
    # Algebra...:
    #     s_1 = ((v_2^2 - v_0^2)/2 - s_2*a_1) / (a_0 - a_1)
    #     stopping_displacement = s_2 - s_1
    var displacement_to_instruction_end: float = \
            (-velocity_x_start * velocity_x_start / 2.0 - \
                displacement_x_from_end * friction_deceleration) / \
            (walk_acceleration - friction_deceleration)
    var stopping_displacement := \
            displacement_x_from_end - displacement_to_instruction_end
    
    return abs(stopping_displacement)


static func calculate_distance_to_stop_from_friction_with_some_backward_acceleration(
        movement_params: MovementParameters,
        surface_properties: SurfaceProperties,
        velocity_x_start: float,
        displacement_x_from_end: float) -> float:
    var distance_from_end := abs(displacement_x_from_end)
    var walk_acceleration := get_walking_acceleration_with_friction_magnitude(
            movement_params,
            surface_properties)
    var friction_deceleration := get_stopping_friction_acceleration_magnitude(
            movement_params,
            surface_properties)
    if displacement_x_from_end > 0.0:
        friction_deceleration *= -1.0
        walk_acceleration *= -1.0
    
    # From a basic equation of motion:
    #     v_2^2 = v_0^2 + 2*a(s_1 - s_0)
    #     v_2 = 0
    #     s_0 = 0
    # Algebra...:
    #     s_1 = -v_0^2 / 2 / a
    var stopping_displacement_with_max_deceleration := \
            -velocity_x_start * velocity_x_start / 2.0 / walk_acceleration
    var is_there_enough_room_to_stop_with_some_acceleration_backwards := \
            abs(stopping_displacement_with_max_deceleration) < \
            distance_from_end
    
    if !is_there_enough_room_to_stop_with_some_acceleration_backwards:
        # We can't stop in time.
        return INF
    
    # There are two parts of the motion:
    # 1.  Constant deceleration from pressing backward.
    # 2.  Constant deceleration from friction.
    # We can use this to calculate the distance of either part.
    # 
    # From basic equations of motion:
    #     v_1^2 = v_0^2 + 2*a_0*(s_1 - s_0)
    #     v_2^2 = v_1^2 + 2*a_1*(s_2 - s_1)
    #     s_0 = 0
    # Algebra...:
    #     s_1 = ((v_2^2 - v_0^2)/2 - s_2*a_1) / (a_0 - a_1)
    #     stopping_displacement = s_2 - s_1
    var displacement_to_instruction_end: float = \
            (-velocity_x_start * velocity_x_start / 2.0 - \
                displacement_x_from_end * friction_deceleration) / \
            (walk_acceleration - friction_deceleration)
    var stopping_displacement := \
            displacement_x_from_end - displacement_to_instruction_end
    
    return abs(stopping_displacement)


static func calculate_distance_to_stop_from_friction_with_turn_around(
        movement_params: MovementParameters,
        surface_properties: SurfaceProperties,
        velocity_start: float,
        displacement: float) -> float:
    var walk_acceleration := get_walking_acceleration_with_friction_magnitude(
            movement_params,
            surface_properties)
    var friction_deceleration := get_stopping_friction_acceleration_magnitude(
            movement_params,
            surface_properties)
    if velocity_start > 0.0:
        walk_acceleration *= -1.0
    else:
        friction_deceleration *= -1.0
    
    # From a basic equation of motion:
    #     v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
    #     v_1 = 0
    # Algebra...:
    #     (s_1 - s_0) = -(v_0^2) / 2 / a
    var displacement_to_end_of_turn_around := \
        -velocity_start * velocity_start / 2.0 / walk_acceleration
    
    var max_horizontal_speed := \
        movement_params.get_max_surface_speed() * \
        surface_properties.speed_multiplier
    
    # From a basic equation of motion:
    #     v^2 = v_0^2 + 2*a*(s - s_0)
    #     v_0 = 0
    # Algebra...:
    #     (s - s_0) = v^2 / 2 / a
    var distance_from_turn_around_to_max_horizontal_speed := \
        max_horizontal_speed * max_horizontal_speed / 2.0 / walk_acceleration
    
    var distance_from_turn_around_to_destination := \
        abs(displacement - displacement_to_end_of_turn_around)
    
    var stopping_distance_from_max_speed := \
        calculate_distance_to_stop_from_friction(
            movement_params,
            surface_properties,
            max_horizontal_speed)
    
    var is_there_enough_room_to_slow_from_max_speed := \
            distance_from_turn_around_to_destination > \
            distance_from_turn_around_to_max_horizontal_speed + \
                stopping_distance_from_max_speed
    
    if is_there_enough_room_to_slow_from_max_speed:
        return stopping_distance_from_max_speed
    
    # There are two parts of the motion:
    # 1.  Constant acceleration from pressing forward.
    # 2.  Constant deceleration from friction.
    # We can use this to calculate the distance of either part.
    # 
    # From basic equations of motion:
    #     v_1^2 = v_0^2 + 2*a_0*(s_1 - s_0)
    #     v_2^2 = v_1^2 + 2*a_1*(s_2 - s_1)
    #     s_0 = 0
    #     v_2 = 0
    # Algebra...:
    #     s_1 = (v_0^2/2 + s_2*a_1) / (a_1 - a_0)
    #     stopping_displacement = s_2 - s_1
    var displacement_to_instruction_end: float = \
            (velocity_start * velocity_start / 2.0 + \
                displacement * friction_deceleration) / \
            (friction_deceleration - walk_acceleration)
    var stopping_displacement := \
        displacement - displacement_to_instruction_end
    
    return abs(stopping_displacement)
