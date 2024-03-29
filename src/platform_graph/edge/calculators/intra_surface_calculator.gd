class_name IntraSurfaceCalculator
extends EdgeCalculator


const NAME := "IntraSurfaceCalculator"
const EDGE_TYPE := EdgeType.INTRA_SURFACE_EDGE
const IS_A_JUMP_CALCULATOR := false
const IS_GRAPHABLE := false


func _init().(
        NAME,
        EDGE_TYPE,
        IS_A_JUMP_CALCULATOR,
        IS_GRAPHABLE) -> void:
    pass


func get_can_traverse_from_surface(
        surface: Surface,
        collision_params: CollisionCalcParams) -> bool:
    # This should never be called
    Sc.logger.error()
    return false


func get_all_inter_surface_edges_from_surface(
        inter_surface_edges_results: Array,
        collision_params: CollisionCalcParams,
        origin_surface: Surface,
        surfaces_in_fall_range_set: Dictionary,
        surfaces_in_jump_range_set: Dictionary) -> void:
    # This should never be called.
    Sc.logger.error()


func calculate_edge(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        velocity_start := Vector2.INF,
        needs_extra_jump_duration := false,
        needs_extra_wall_land_horizontal_speed := false,
        basis_edge: EdgeAttempt = null) -> Edge:
    return create(
            position_start,
            position_end,
            velocity_start,
            collision_params.movement_params)


func _calculate_is_degenerate(
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> bool:
    var displacement := end.target_point - start.target_point
    if start.surface.side == SurfaceSide.FLOOR or \
            start.surface.side == SurfaceSide.CEILING:
        return displacement.x < 0.00001 and displacement.x > -0.00001
    else:
        return displacement.y < 0.00001 and displacement.y > -0.00001


func create(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        movement_params: MovementParameters) -> IntraSurfaceEdge:
    var is_degenerate: bool = _calculate_is_degenerate(
            start,
            end)
    var distance := calculate_distance(
            movement_params,
            start,
            end)
    var duration := calculate_duration(
            movement_params,
            start,
            end,
            velocity_start)
    var velocity_end := _calculate_velocity_end(
            start,
            end,
            velocity_start,
            movement_params)
    var is_moving_clockwise := _calculate_is_moving_clockwise(
            start,
            end)
    var stopping_distance := _calculate_stopping_distance(
            start,
            end,
            velocity_start,
            movement_params)
    var instructions := _calculate_instructions(
            start,
            end,
            duration)
    var trajectory := _calculate_trajectory(
            start,
            end,
            velocity_start,
            duration,
            is_degenerate,
            movement_params)
    
    return IntraSurfaceEdge.new(
            self,
            start,
            end,
            velocity_start,
            velocity_end,
            distance,
            duration,
            is_moving_clockwise,
            stopping_distance,
            is_degenerate,
            movement_params,
            instructions,
            trajectory)


func create_correction_interstitial(
        position: PositionAlongSurface,
        velocity: Vector2,
        movement_params: MovementParameters) -> IntraSurfaceEdge:
    return create(
            position,
            position,
            velocity,
            movement_params)


func update_terminal(
        edge: IntraSurfaceEdge,
        is_start: bool,
        target_point: Vector2) -> void:
    var position_along_surface := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    target_point,
                    edge.start_position_along_surface.surface,
                    edge.movement_params.collider,
                    true)
    if is_start:
        edge.start_position_along_surface = position_along_surface
    else:
        edge.end_position_along_surface = position_along_surface
    _update(edge)


func update_for_surface_state(
        edge: IntraSurfaceEdge,
        surface_state: CharacterSurfaceState,
        is_final_edge: bool) -> void:
    edge.start_position_along_surface = \
            surface_state.center_position_along_surface
    edge.velocity_start = surface_state.velocity
    _update(edge)


func _update(edge: IntraSurfaceEdge) -> void:
    var start := edge.start_position_along_surface
    var end := edge.end_position_along_surface
    var velocity_start := edge.velocity_start
    var movement_params := edge.movement_params
    
    var is_degenerate: bool = _calculate_is_degenerate(
            start,
            end)
    var distance := calculate_distance(
            movement_params,
            start,
            end)
    var duration := calculate_duration(
            movement_params,
            start,
            end,
            velocity_start)
    var velocity_end := _calculate_velocity_end(
            start,
            end,
            velocity_start,
            movement_params)
    var is_moving_clockwise := _calculate_is_moving_clockwise(
            start,
            end)
    var stopping_distance := _calculate_stopping_distance(
            start,
            end,
            velocity_start,
            movement_params)
    var instructions := _calculate_instructions(
            start,
            end,
            duration)
    var trajectory := _calculate_trajectory(
            start,
            end,
            velocity_start,
            duration,
            is_degenerate,
            movement_params)
    
    edge.start_position_along_surface = start
    edge.end_position_along_surface = end
    edge.distance = distance
    edge.duration = duration
    edge.velocity_end = velocity_end
    edge.is_moving_clockwise = is_moving_clockwise
    edge.instructions = instructions
    edge.trajectory = trajectory


func calculate_distance(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> float:
    var is_degenerate: bool = _calculate_is_degenerate(start, end)
    if is_degenerate:
        return 0.00001
    var displacement := end.target_point - start.target_point
    var is_horizontal := \
            start.surface.side == SurfaceSide.FLOOR or \
            start.surface.side == SurfaceSide.CEILING
    return abs(displacement.x) if \
            is_horizontal else \
            abs(displacement.y)


func calculate_duration(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start := Vector2.ZERO) -> float:
    var is_degenerate: bool = _calculate_is_degenerate(start, end)
    if is_degenerate:
        return 0.00001
    
    var displacement := end.target_point - start.target_point
    
    match start.side:
        SurfaceSide.FLOOR:
            var displacement_x := displacement.x
            var velocity_start_x := velocity_start.x
            # Our calculations currently assume that acceleration is in the
            # positive direction, so let's make sure our velocity/displacement
            # align with that.
            if displacement_x < 0.0:
                velocity_start_x = -velocity_start_x
                displacement_x = -displacement_x
            var duration := MovementUtils.calculate_time_to_walk(
                    displacement_x,
                    velocity_start_x,
                    movement_params)
            assert(!is_inf(duration))
            return duration
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var is_climbing_upward := displacement.y < 0
            return MovementUtils.calculate_time_to_climb(
                    abs(displacement.y),
                    is_climbing_upward,
                    movement_params)
        SurfaceSide.CEILING:
            return MovementUtils.calculate_time_to_crawl_on_ceiling(
                    abs(displacement.x),
                    movement_params)
        _:
            Sc.logger.error()
            return INF


func _calculate_velocity_end(
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


func _calculate_is_moving_clockwise(
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> bool:
    var displacement := end.target_point - start.target_point
    match start.surface.side:
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


func _calculate_instructions(
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


func _calculate_trajectory(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        duration: float,
        is_degenerate: bool,
        movement_params: MovementParameters) -> EdgeTrajectory:
    var trajectory := EdgeTrajectory.new()
    
    trajectory.waypoint_positions = [
        start.target_point,
        end.target_point,
    ]
    
    if !movement_params.includes_discrete_trajectory_state and \
            !movement_params \
                    .includes_continuous_trajectory_positions and \
            !movement_params.includes_continuous_trajectory_velocities:
        return trajectory
    
    if is_degenerate:
        var positions := [start.target_point]
        var velocities := [velocity_start]
        if movement_params.includes_discrete_trajectory_state:
            trajectory.frame_discrete_positions_from_test = \
                    PoolVector2Array(positions)
        if movement_params.includes_continuous_trajectory_positions:
            trajectory.frame_continuous_positions_from_steps = \
                    PoolVector2Array(positions)
        if movement_params.includes_continuous_trajectory_velocities:
            trajectory.frame_continuous_velocities_from_steps = \
                    PoolVector2Array(velocities)
        trajectory.distance_from_continuous_trajectory = 0.00001
        return trajectory
    
    var displacement := end.target_point - start.target_point
    
    var frame_count := int(max(ceil(duration / Time.PHYSICS_TIME_STEP), 1))
    var frame_index := 0
    var position := start.target_point
    var velocity := velocity_start
    var acceleration := Vector2.ZERO
    
    var positions := []
    positions.resize(frame_count)
    var velocities := []
    velocities.resize(frame_count)
    
    match start.surface.side:
        SurfaceSide.FLOOR:
            velocity.x = velocity_start.x
            velocity.y = 0.0
            acceleration.x = \
                    movement_params.walk_acceleration if \
                    displacement.x > 0 else \
                    -movement_params.walk_acceleration
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            velocity.x = 0.0
            velocity.y = \
                    movement_params.climb_down_speed if \
                    displacement.y > 0 else \
                    movement_params.climb_up_speed
        SurfaceSide.CEILING:
            velocity.x = \
                    movement_params.ceiling_crawl_speed if \
                    displacement.x > 0 else \
                    -movement_params.ceiling_crawl_speed
            velocity.y = 0.0
        _:
            Sc.logger.error()
    
    for i in frame_count:
        positions[i] = position
        velocities[i] = velocity
        
        position += velocity * Time.PHYSICS_TIME_STEP
        position = Sc.geometry.project_shape_onto_surface(
                position,
                movement_params.collider,
                start.surface,
                true)
        velocity += acceleration * Time.PHYSICS_TIME_STEP
        velocity.x = clamp(
                velocity.x,
                -movement_params.max_horizontal_speed_default,
                movement_params.max_horizontal_speed_default)
    
    if movement_params.includes_discrete_trajectory_state:
        trajectory.frame_discrete_positions_from_test = \
                PoolVector2Array(positions)
    if movement_params.includes_continuous_trajectory_positions:
        trajectory.frame_continuous_positions_from_steps = \
                PoolVector2Array(positions)
    if movement_params.includes_continuous_trajectory_velocities:
        trajectory.frame_continuous_velocities_from_steps = \
                PoolVector2Array(velocities)
    
    # Update the trajectory distance.
    trajectory.distance_from_continuous_trajectory = \
            EdgeTrajectoryUtils.sum_distance_between_frames(positions)
    
    return trajectory


# Calculate the distance from the end position at which the move button should
# be released, so that the character comes to rest at the desired end position
# after decelerating due to friction (and with accelerating, or coasting at
# max-speed, until starting deceleration).
func _calculate_stopping_distance(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        movement_params: MovementParameters) -> float:
    if movement_params.forces_character_position_to_match_path_at_end:
        return 0.0
    
    var displacement := end.target_point - start.target_point
    
    # TODO: Add support for acceleration and friction alongs walls and
    #       ceilings.
    match end.surface.side:
        SurfaceSide.FLOOR:
            var friction_coefficient: float = \
                    movement_params.friction_coefficient * \
                    end.surface.tile_map.collision_friction
            var stopping_distance := MovementUtils \
                    .calculate_distance_to_stop_from_friction_with_acceleration_to_non_max_speed(
                            movement_params,
                            velocity_start.x,
                            displacement.x,
                            movement_params.gravity_fast_fall,
                            friction_coefficient)
            return stopping_distance if \
                    abs(displacement.x) - stopping_distance > \
                        IntraSurfaceEdge \
                                .REACHED_DESTINATION_DISTANCE_THRESHOLD else \
                    max(abs(displacement.x) - \
                        IntraSurfaceEdge \
                                .REACHED_DESTINATION_DISTANCE_THRESHOLD - 2.0,
                        0.0)
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var climb_speed := \
                    abs(movement_params.climb_up_speed) if \
                    displacement.y < 0 else \
                    abs(movement_params.climb_down_speed)
            return climb_speed * Time.PHYSICS_TIME_STEP + 0.01
        SurfaceSide.CEILING:
            var climb_speed := abs(movement_params.ceiling_crawl_speed)
            return climb_speed * Time.PHYSICS_TIME_STEP + 0.01
        _:
            Sc.logger.error()
            return INF
