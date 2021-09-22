class_name IntraSurfaceEdgeFactory


# FIXME: LEFT OFF HERE: -------------------------------------------------------


static func create(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        movement_params: MovementParameters) -> IntraSurfaceEdge:
    var distance := calculate_distance(movement_params, start, end)
    var duration := calculate_duration(movement_params, start, end, distance)
    var velocity_end := _calculate_velocity_end
    var is_moving_clockwise := _calculate_is_moving_clockwise(start, end)
    var instructions := _calculate_instructions(start, end, duration)
    var trajectory := _calculate_trajectory(start, end)
    
    return IntraSurfaceEdge.new(
            start,
            end,
            velocity_start,
            velocity_end,
            distance,
            duration,
            is_moving_clockwise,
            movement_params,
            instructions,
            trajectory)


static func create_correction_interstitial() -> IntraSurfaceEdge:
    pass


static func calculate_distance(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> float:
    return start.target_point.distance_to(end.target_point)


static func calculate_duration(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        distance: float) -> float:
    match start.side:
        SurfaceSide.FLOOR:
            return MovementUtils.calculate_time_to_walk(
                    distance,
                    0.0,
                    movement_params)
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var is_climbing_upward := end.target_point.y < start.target_point.y
            return MovementUtils.calculate_time_to_climb(
                    distance,
                    is_climbing_upward,
                    movement_params)
        SurfaceSide.CEILING:
            return MovementUtils.calculate_time_to_crawl_on_ceiling(
                    distance,
                    movement_params)
        _:
            Sc.logger.error()
            return INF


static func _calculate_velocity_end(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        movement_params: MovementParameters) -> Vector2:
    var displacement := end.target_point - start.target_point
    
    match start.side:
        SurfaceSide.FLOOR:
            # We need to calculate the end velocity, taking into account whether
            # we will have had enough distance to reach max horizontal speed.
            var acceleration := \
                    movement_params.walk_acceleration if \
                    displacement.x > 0.0 else \
                    -movement_params.walk_acceleration
            var velocity_end_x: float = \
                    MovementUtils.calculate_velocity_end_for_displacement(
                            displacement.x,
                            velocity_start.x,
                            acceleration,
                            movement_params.max_horizontal_speed_default)
            return Vector2(velocity_end_x, 0.0)
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            # We use a constant speed (no acceleration) when climbing.
            var velocity_end_y := \
                    movement_params.climb_up_speed if \
                    displacement.y < 0.0 else \
                    movement_params.climb_down_speed
            return Vector2(0.0, velocity_end_y)
        SurfaceSide.CEILING:
            # We use a constant speed (no acceleration) when crawling on the
            # ceiling.
            var velocity_end_x := \
                    movement_params.ceiling_crawl_speed if \
                    displacement.x > 0.0 else \
                    -movement_params.ceiling_crawl_speed
            return Vector2(velocity_end_x, 0.0)
        _:
            Sc.logger.error()
            return Vector2.INF


static func _calculate_is_moving_clockwise(
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> bool:
    var displacement := end.target_point - start.target_point
    match surface.side:
        SurfaceSide.FLOOR:
            return displacement.x >= 0
        SurfaceSide.LEFT_WALL:
            return displacement.y >= 0
        SurfaceSide.RIGHT_WALL:
            return displacement.y <= 0
        SurfaceSide.CEILING:
            return displacement.x <= 0
        _:
            Sc.logger.error()
            return false


static func _calculate_instructions(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        duration: float) -> EdgeInstructions:
    if start == null or end == null:
        return null
    
    var input_key: String
    var is_wall_surface := end.surface.normal.y == 0.0
    if is_wall_surface:
        if start.target_point.y < end.target_point.y:
            input_key = "md"
        else:
            input_key = "mu"
    else:
        if start.target_point.x < end.target_point.x:
            input_key = "mr"
        else:
            input_key = "ml"
    
    var instruction := EdgeInstruction.new(
            input_key,
            0.0,
            true)
    
    return EdgeInstructions.new(
            [instruction],
            duration,
            false)


static func _calculate_trajectory(
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> EdgeTrajectory:
    pass


# Calculate the distance from the end position at which the move button should
# be released, so that the character comes to rest at the desired end position
# after decelerating due to friction (and with accelerating, or coasting at
# max-speed, until starting deceleration).
static func _calculate_stopping_distance(
        movement_params: MovementParameters,
        edge: IntraSurfaceEdge,
        velocity_start: Vector2,
        displacement_to_end: Vector2) -> float:
    if movement_params.forces_character_position_to_match_path_at_end:
        return 0.0
    
    # TODO: Add support for acceleration and friction alongs walls and
    #       ceilings.
    match edge.get_end_surface().side:
        SurfaceSide.FLOOR:
            var friction_coefficient: float = \
                    movement_params.friction_coefficient * \
                    edge.get_end_surface().tile_map.collision_friction
            var stopping_distance := MovementUtils \
                    .calculate_distance_to_stop_from_friction_with_acceleration_to_non_max_speed(
                            movement_params,
                            velocity_start.x,
                            displacement_to_end.x,
                            movement_params.gravity_fast_fall,
                            friction_coefficient)
            return stopping_distance if \
                    abs(displacement_to_end.x) - stopping_distance > \
                            REACHED_DESTINATION_DISTANCE_THRESHOLD else \
                    max(abs(displacement_to_end.x) - \
                            REACHED_DESTINATION_DISTANCE_THRESHOLD - 2.0, 0.0)
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var climb_speed := \
                    abs(movement_params.climb_up_speed) if \
                    displacement_to_end.y < 0 else \
                    abs(movement_params.climb_down_speed)
            return climb_speed * Time.PHYSICS_TIME_STEP + 0.01
        SurfaceSide.CEILING:
            var climb_speed := abs(movement_params.ceiling_crawl_speed)
            return climb_speed * Time.PHYSICS_TIME_STEP + 0.01
        _:
            Sc.logger.error()
            return INF
