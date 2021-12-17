class_name IntraSurfaceCalculator
extends EdgeCalculator


const NAME := "IntraSurfaceCalculator"
const EDGE_TYPE := EdgeType.INTRA_SURFACE_EDGE
const IS_A_JUMP_CALCULATOR := false
const IS_GRAPHABLE := false

const _UNEXPECTED_EARLY_COLLISION_DISTANCE_SQUARED_THRESHOLD := 16.0 * 16.0


func _init().(
        NAME,
        EDGE_TYPE,
        IS_A_JUMP_CALCULATOR,
        IS_GRAPHABLE) -> void:
    pass


func get_can_traverse_from_surface(
        surface: Surface,
        collision_params: CollisionCalcParams) -> bool:
    # This should never be called.
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
            collision_params.movement_params,
            false,
            false)


func _calculate_is_degenerate(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        is_backtracking_edge_to_end_at_destination: bool) -> bool:
    return Sc.geometry.are_points_equal_with_epsilon(
                end.target_point,
                start.target_point,
                0.0001) and \
            (!is_backtracking_edge_to_end_at_destination or \
                Sc.geometry.are_points_equal_with_epsilon(
                    velocity_start,
                    Vector2.ZERO,
                    0.01))


func create(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        movement_params: MovementParameters,
        includes_deceleration_at_end: bool,
        is_backtracking_edge_to_end_at_destination: bool,
        allows_unexpected_collisions_with_concave_neighbors := false \
        ) -> IntraSurfaceEdge:
    assert(start.surface == end.surface)
    
    var edge := IntraSurfaceEdge.new()
    
    edge.surface_type = SurfaceType.get_type_from_side(start.side)
    edge.calculator = self
    edge.start_position_along_surface = PositionAlongSurface.new(start)
    edge.end_position_along_surface = PositionAlongSurface.new(end)
    edge.velocity_start = velocity_start
    edge.movement_params = movement_params
    edge.includes_deceleration_at_end = includes_deceleration_at_end
    edge.is_backtracking_edge_to_end_at_destination = \
            is_backtracking_edge_to_end_at_destination
    
    _update(edge)
    
    if !allows_unexpected_collisions_with_concave_neighbors and \
            edge.trajectory.collided_early:
        var early_collision_position: Vector2 = \
                edge.trajectory.frame_continuous_positions_from_steps[ \
                        edge.trajectory.frame_continuous_positions_from_steps \
                                .size() - 1] if \
                !edge.trajectory.frame_continuous_positions_from_steps \
                        .empty() else \
                edge.trajectory.frame_discrete_positions_from_test[ \
                        edge.trajectory.frame_discrete_positions_from_test \
                                .size() - 1] if \
                !edge.trajectory.frame_discrete_positions_from_test \
                        .empty() else \
                Vector2.INF
        if early_collision_position.distance_squared_to(end.target_point) > \
                _UNEXPECTED_EARLY_COLLISION_DISTANCE_SQUARED_THRESHOLD:
            Sc.logger.error()
    
    return edge


func create_correction_interstitial(
        position: PositionAlongSurface,
        velocity: Vector2,
        movement_params: MovementParameters) -> IntraSurfaceEdge:
    return create(
            position,
            position,
            velocity,
            movement_params,
            false,
            false)


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
        PositionAlongSurface.copy(
                edge.start_position_along_surface,
                position_along_surface)
    else:
        PositionAlongSurface.copy(
                edge.end_position_along_surface,
                position_along_surface)
    _update(edge)


func update_for_surface_state(
        edge: IntraSurfaceEdge,
        surface_state: CharacterSurfaceState,
        is_final_edge: bool) -> void:
    var start_surface := edge.get_start_surface()
    assert(surface_state.grabbed_surface == start_surface)
    PositionAlongSurface.copy(
            edge.start_position_along_surface,
            surface_state.center_position_along_surface)
    edge.velocity_start = surface_state.velocity
    var max_horizontal_speed := \
            edge.movement_params.get_max_surface_speed() * \
            start_surface.properties.speed_multiplier
    edge.velocity_start.x = clamp(
            edge.velocity_start.x,
            -max_horizontal_speed,
            max_horizontal_speed)
    _update(edge)


func update_for_start_velocity(
        edge: IntraSurfaceEdge,
        velocity_start: Vector2) -> void:
    edge.velocity_start = velocity_start
    var max_horizontal_speed := \
            edge.movement_params.get_max_surface_speed() * \
            edge.get_start_surface().properties.speed_multiplier
    edge.velocity_start.x = clamp(
            edge.velocity_start.x,
            -max_horizontal_speed,
            max_horizontal_speed)
    _update(edge)


func _update(edge: IntraSurfaceEdge) -> void:
    var start := edge.start_position_along_surface
    var end := edge.end_position_along_surface
    var velocity_start := edge.velocity_start
    var includes_deceleration_at_end := edge.includes_deceleration_at_end
    var is_backtracking_edge_to_end_at_destination := \
            edge.is_backtracking_edge_to_end_at_destination
    var movement_params := edge.movement_params
    
    var is_degenerate := _calculate_is_degenerate(
            start,
            end,
            velocity_start,
            is_backtracking_edge_to_end_at_destination)
    var is_moving_clockwise := _calculate_is_moving_clockwise(
            start,
            end)
    var distance := calculate_distance(
            movement_params,
            start,
            end)
    var is_pressing_left := _calculate_is_pressing_left(
            movement_params,
            start,
            end,
            velocity_start,
            includes_deceleration_at_end)
    var is_pressing_forward := _calculate_is_pressing_forward(
            movement_params,
            start,
            end,
            velocity_start,
            is_pressing_left)
    var stopping_distance := _calculate_stopping_distance(
            movement_params,
            start,
            end,
            velocity_start,
            is_pressing_left,
            is_pressing_forward,
            includes_deceleration_at_end)
    var release_time := _calculate_release_time(
            movement_params,
            start,
            end,
            velocity_start,
            stopping_distance,
            is_pressing_left,
            is_pressing_forward,
            is_degenerate)
    var release_position := _calculate_release_position(
            movement_params,
            start,
            end,
            velocity_start,
            release_time,
            is_pressing_left)
    var release_velocity := _calculate_release_velocity(
            movement_params,
            start,
            end,
            velocity_start,
            release_time,
            is_pressing_left)
    var velocity_end := _calculate_velocity_end(
            movement_params,
            start,
            end,
            velocity_start,
            stopping_distance,
            is_pressing_left,
            is_pressing_forward,
            includes_deceleration_at_end,
            is_degenerate)
    var duration := calculate_duration(
            movement_params,
            start,
            end,
            velocity_start,
            stopping_distance,
            release_time,
            release_velocity,
            is_pressing_left,
            is_pressing_forward,
            includes_deceleration_at_end,
            is_degenerate)
    var trajectory := _calculate_trajectory(
            movement_params,
            start,
            end,
            velocity_start,
            duration,
            release_time,
            is_pressing_left,
            is_moving_clockwise,
            is_degenerate)
    
    # We might need to shorten our expected movement for a concave next neighbor
    # (which can form a tight cusp).
    if trajectory.collided_early:
        var early_end := \
                trajectory.frame_continuous_positions_from_steps[ \
                    trajectory \
                        .frame_continuous_positions_from_steps.size() - 1] if \
                !trajectory.frame_continuous_positions_from_steps.empty() else \
                trajectory.frame_discrete_positions_from_test[ \
                    trajectory \
                        .frame_discrete_positions_from_test.size() - 1] if \
                !trajectory.frame_discrete_positions_from_test.empty() else \
                Vector2.INF
        if early_end != Vector2.INF:
            end = PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            early_end,
                            end.surface,
                            movement_params.collider,
                            false)
            is_degenerate = _calculate_is_degenerate(
                    start,
                    end,
                    velocity_start,
                    is_backtracking_edge_to_end_at_destination)
            is_moving_clockwise = _calculate_is_moving_clockwise(
                    start,
                    end)
            distance = calculate_distance(
                    movement_params,
                    start,
                    end)
            is_pressing_left = _calculate_is_pressing_left(
                    movement_params,
                    start,
                    end,
                    velocity_start,
                    includes_deceleration_at_end)
            is_pressing_forward = _calculate_is_pressing_forward(
                    movement_params,
                    start,
                    end,
                    velocity_start,
                    is_pressing_left)
            stopping_distance = _calculate_stopping_distance(
                    movement_params,
                    start,
                    end,
                    velocity_start,
                    is_pressing_left,
                    is_pressing_forward,
                    includes_deceleration_at_end)
            release_time = _calculate_release_time(
                    movement_params,
                    start,
                    end,
                    velocity_start,
                    stopping_distance,
                    is_pressing_left,
                    is_pressing_forward,
                    is_degenerate)
            release_position = _calculate_release_position(
                    movement_params,
                    start,
                    end,
                    velocity_start,
                    release_time,
                    is_pressing_left)
            release_velocity = _calculate_release_velocity(
                    movement_params,
                    start,
                    end,
                    velocity_start,
                    release_time,
                    is_pressing_left)
            velocity_end = _calculate_velocity_end(
                    movement_params,
                    start,
                    end,
                    velocity_start,
                    stopping_distance,
                    is_pressing_left,
                    is_pressing_forward,
                    includes_deceleration_at_end,
                    is_degenerate)
            duration = calculate_duration(
                    movement_params,
                    start,
                    end,
                    velocity_start,
                    stopping_distance,
                    release_time,
                    release_velocity,
                    is_pressing_left,
                    is_pressing_forward,
                    includes_deceleration_at_end,
                    is_degenerate)
    
    if trajectory.skipped_duplicated_positions:
        var previous_duration := duration
        duration = \
                trajectory.frame_continuous_positions_from_steps.size() * \
                Time.PHYSICS_TIME_STEP
        var lost_time := previous_duration - duration
        # TODO: These could be inaccurate.
        release_time -= lost_time
        release_position = trajectory.frame_continuous_positions_from_steps[ \
                trajectory.position_duplication_start_index]
        release_velocity = trajectory.frame_continuous_velocities_from_steps[ \
                trajectory.position_duplication_start_index]
    
    var instructions := _calculate_instructions(
            start,
            end,
            duration,
            release_time,
            is_pressing_left)
    
    assert(!is_inf(release_time))
    assert(!is_inf(duration))
    assert(!Sc.geometry.is_point_partial_inf(release_position))
    assert(!Sc.geometry.is_point_partial_inf(release_velocity))
    assert(!Sc.geometry.is_point_partial_inf(velocity_end))
    
    PositionAlongSurface.copy(
            edge.start_position_along_surface,
            start)
    PositionAlongSurface.copy(
            edge.end_position_along_surface,
            end)
    edge.distance = distance
    edge.duration = duration
    edge.velocity_end = velocity_end
    edge.is_moving_clockwise = is_moving_clockwise
    edge.is_pressing_left = is_pressing_left
    edge.stopping_distance = stopping_distance
    edge.release_time = release_time
    edge.release_position = release_position
    edge.release_velocity = release_velocity
    edge.is_degenerate = is_degenerate
    edge.instructions = instructions
    edge.trajectory = trajectory


func calculate_distance(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start := Vector2.ZERO,
        is_backtracking_edge_to_end_at_destination := false) -> float:
    # FIXME: LEFT OFF HERE: ------------------
    # - Calculate turn-around point, at v=0.
    # - Sum distance from start to turn-around, and from turn-around to end.
    if _calculate_is_degenerate(
            start,
            end,
            velocity_start,
            is_backtracking_edge_to_end_at_destination):
        return 0.00001
    var displacement := end.target_point - start.target_point
    var is_horizontal := \
            start.surface.side == SurfaceSide.FLOOR or \
            start.surface.side == SurfaceSide.CEILING
    return abs(displacement.x) if \
            is_horizontal else \
            abs(displacement.y)


func calculate_duration_with_zero_start_velocity(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> float:
    if _calculate_is_degenerate(start, end, Vector2.ZERO, false):
        return 0.00001
    
    var displacement := end.target_point - start.target_point
    
    match start.side:
        SurfaceSide.FLOOR:
            var acceleration_magnitude := MovementUtils \
                    .get_walking_acceleration_with_friction_magnitude(
                        movement_params,
                        start.surface.properties)
            var max_speed := \
                    movement_params.get_max_surface_speed() * \
                    start.surface.properties.speed_multiplier
            var duration := MovementUtils.calculate_duration_for_displacement(
                    abs(displacement.x),
                    0.0,
                    acceleration_magnitude,
                    max_speed)
            assert(!is_inf(duration))
            return duration
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var is_climbing_upward := displacement.y < 0
            return MovementUtils.calculate_time_to_climb(
                    abs(displacement.y),
                    is_climbing_upward,
                    start.surface,
                    movement_params)
        SurfaceSide.CEILING:
            return MovementUtils.calculate_time_to_crawl_on_ceiling(
                    abs(displacement.x),
                    start.surface,
                    movement_params)
        _:
            Sc.logger.error()
            return INF


func calculate_duration(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        stopping_distance: float,
        release_time: float,
        release_velocity: Vector2,
        is_pressing_left: bool,
        is_pressing_forward: bool,
        includes_deceleration_at_end: bool,
        is_degenerate: bool) -> float:
    if is_degenerate:
        return 0.00001
    
    var displacement := end.target_point - start.target_point
    
    if start.side == SurfaceSide.FLOOR and \
            includes_deceleration_at_end:
        var has_enough_time_to_decelerate_to_zero := \
                is_pressing_forward or \
                !is_inf(stopping_distance)
        if has_enough_time_to_decelerate_to_zero:
            # We do have enough time to decelerate to zero speed at the end.
            # From a basic equation of motion:
            #     v_1 = v_0 + a*t
            #     v_1 = 0.0
            # Algebra...:
            #     t = -v_0 / a
            var deceleration_magnitude := MovementUtils \
                    .get_stopping_friction_acceleration_magnitude(
                        movement_params,
                        start.surface.properties)
            var deceleration_time := \
                    abs(release_velocity.x) / deceleration_magnitude
            return release_time + deceleration_time
        else:
            # We don't have enough time to decelerate to zero speed at the end.
            assert(!is_pressing_forward)
            var acceleration_magnitude := MovementUtils \
                    .get_walking_acceleration_with_friction_magnitude(
                        movement_params,
                        start.surface.properties)
            var acceleration_x := \
                    -acceleration_magnitude if \
                    is_pressing_left else \
                    acceleration_magnitude
            var duration: float = MovementUtils.calculate_movement_duration(
                    displacement.x,
                    velocity_start.x,
                    acceleration_x,
                    true,
                    0.0,
                    false,
                    false)
            assert(!is_inf(duration))
            return duration
        
    else:
        return release_time


func _calculate_velocity_end(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        stopping_distance: float,
        is_pressing_left: bool,
        is_pressing_forward: bool,
        includes_deceleration_at_end: bool,
        is_degenerate: bool) -> Vector2:
    var displacement := end.target_point - start.target_point
    
    match start.side:
        SurfaceSide.FLOOR:
            if is_degenerate:
                return velocity_start
            
            var has_enough_time_to_decelerate_to_zero := \
                    includes_deceleration_at_end and \
                    (is_pressing_forward or \
                    !is_inf(stopping_distance))
            
            if !has_enough_time_to_decelerate_to_zero:
                # We don't have enough time to decelerate to zero speed at the
                # end.
                assert(!includes_deceleration_at_end or \
                        !is_pressing_forward)
                var acceleration_magnitude := MovementUtils \
                        .get_walking_acceleration_with_friction_magnitude(
                            movement_params,
                            start.surface.properties)
                var acceleration_x := \
                        -acceleration_magnitude if \
                        is_pressing_left else \
                        acceleration_magnitude
                var max_horizontal_speed := \
                        movement_params.get_max_surface_speed() * \
                        start.surface.properties.speed_multiplier
                var velocity_end_x: float = \
                        MovementUtils.calculate_velocity_end_for_displacement(
                            displacement.x,
                            velocity_start.x,
                            acceleration_x,
                            max_horizontal_speed,
                            true)
                return Vector2(velocity_end_x, 0.0)
                
            else:
                # We do have enough time to decelerate to zero speed at the end.
                return Vector2.ZERO
            
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            # We use a constant speed (no acceleration) when climbing.
            var velocity_end_y := \
                    movement_params.climb_up_speed if \
                    displacement.y < 0.0 else \
                    movement_params.climb_down_speed
            velocity_end_y *= start.surface.properties.speed_multiplier
            return Vector2(0.0, velocity_end_y)
        SurfaceSide.CEILING:
            # We use a constant speed (no acceleration) when crawling on the
            # ceiling.
            var velocity_end_x := \
                    -movement_params.ceiling_crawl_speed if \
                    is_pressing_left else \
                    movement_params.ceiling_crawl_speed
            velocity_end_x *= start.surface.properties.speed_multiplier
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
        duration: float,
        release_time: float,
        is_pressing_left: bool) -> EdgeInstructions:
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
        if is_pressing_left:
            input_key = "ml"
        else:
            input_key = "mr"
    
    var press := EdgeInstruction.new(
            input_key,
            0.0,
            true)
    var release := EdgeInstruction.new(
            input_key,
            release_time,
            false)
    
    return EdgeInstructions.new(
            [press, release],
            duration,
            false)


func _calculate_trajectory(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        duration: float,
        release_time: float,
        is_pressing_left: bool,
        is_moving_clockwise: bool,
        is_degenerate: bool) -> EdgeTrajectory:
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
    
    var next_neighbor := \
            end.surface.clockwise_neighbor if \
            is_moving_clockwise else \
            end.surface.counter_clockwise_neighbor
    var is_next_neighbor_concave := \
            next_neighbor == end.surface.clockwise_concave_neighbor or \
            next_neighbor == end.surface.counter_clockwise_concave_neighbor
    var next_neighbor_normal_side_override := SurfaceSide.NONE
    if is_next_neighbor_concave:
        match end.surface.side:
            SurfaceSide.FLOOR:
                next_neighbor_normal_side_override = \
                        SurfaceSide.RIGHT_WALL if \
                        is_moving_clockwise else \
                        SurfaceSide.LEFT_WALL
            SurfaceSide.LEFT_WALL:
                next_neighbor_normal_side_override = \
                        SurfaceSide.FLOOR if \
                        is_moving_clockwise else \
                        SurfaceSide.CEILING
            SurfaceSide.RIGHT_WALL:
                next_neighbor_normal_side_override = \
                        SurfaceSide.CEILING if \
                        is_moving_clockwise else \
                        SurfaceSide.FLOOR
            SurfaceSide.CEILING:
                next_neighbor_normal_side_override = \
                        SurfaceSide.LEFT_WALL if \
                        is_moving_clockwise else \
                        SurfaceSide.RIGHT_WALL
            _:
                Sc.logger.error()
    
    var ran_into_concave_next_neighbor := false
    var position_duplication_start_index := -1
    var position_duplication_count := 0
    
    var displacement := end.target_point - start.target_point
    var max_horizontal_speed := \
            movement_params.get_max_surface_speed() * \
            start.surface.properties.speed_multiplier
    
    var frame_count := int(max(ceil(duration / Time.PHYSICS_TIME_STEP), 1))
    var frame_index := 0
    var previous_position := Vector2.INF
    var previous_velocity := Vector2.INF
    var position := start.target_point
    var velocity := velocity_start
    var acceleration_with_pressing := Vector2.ZERO
    var deceleration_with_friction := Vector2.ZERO
    
    var positions := []
    positions.resize(frame_count)
    var velocities := []
    velocities.resize(frame_count)
    
    match start.surface.side:
        SurfaceSide.FLOOR:
            velocity.x = velocity_start.x
            velocity.y = 0.0
            var acceleration_with_pressing_magnitude := MovementUtils \
                    .get_walking_acceleration_with_friction_magnitude(
                        movement_params,
                        start.surface.properties)
            acceleration_with_pressing.x = \
                    -acceleration_with_pressing_magnitude if \
                    is_pressing_left else \
                    acceleration_with_pressing_magnitude
            var deceleration_with_friction_magnitude := MovementUtils \
                    .get_stopping_friction_acceleration_magnitude(
                        movement_params,
                        start.surface.properties)
            deceleration_with_friction.x = \
                    deceleration_with_friction_magnitude if \
                    is_pressing_left else \
                    -deceleration_with_friction_magnitude
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            velocity.x = 0.0
            velocity.y = \
                    movement_params.climb_down_speed if \
                    displacement.y > 0 else \
                    movement_params.climb_up_speed
            velocity.y *= start.surface.properties.speed_multiplier
        SurfaceSide.CEILING:
            velocity.x = \
                    -movement_params.ceiling_crawl_speed if \
                    is_pressing_left else \
                    movement_params.ceiling_crawl_speed
            velocity.x *= start.surface.properties.speed_multiplier
            velocity.y = 0.0
        _:
            Sc.logger.error()
    
    # These min/max limits are used to ensure the last frames don't pass the
    # expected values.
    var velocity_x_min := -max_horizontal_speed
    var velocity_x_max := max_horizontal_speed
    var position_x_min: float
    var position_x_max: float
    if displacement.x > 0:
        position_x_min = start.surface.first_point.x + 0.1
        position_x_max = end.target_point.x
    else:
        position_x_min = end.target_point.x
        position_x_max = start.surface.last_point.x - 0.1
    
    while frame_index + position_duplication_count < frame_count:
        # TODO: Replace this quick fix with something better.
        if position != previous_position:
            # -   With our current implementation, it's possible for multiple
            #     adjacent frames to be snapped to the end of the surface.
            # -   In that case, we skip any duplicated positions.
            positions[frame_index] = position
            velocities[frame_index] = velocity
        else:
            position_duplication_count += 1
            frame_index -= 1
            if position_duplication_start_index < 0:
                position_duplication_start_index = frame_index
            assert(Sc.geometry.are_floats_equal_with_epsilon(
                        position.x,
                        position_x_min,
                        0.01) or \
                    Sc.geometry.are_floats_equal_with_epsilon(
                        position.x,
                        position_x_max,
                        0.01) or \
                    Sc.geometry.are_floats_equal_with_epsilon(
                        previous_velocity.x,
                        0.0,
                        0.01))
        
        frame_index += 1
        var frame_time := \
                (frame_index + position_duplication_count) * \
                Time.PHYSICS_TIME_STEP
        var acceleration := \
                acceleration_with_pressing if \
                frame_time < release_time else \
                deceleration_with_friction
        previous_position = position
        position += velocity * Time.PHYSICS_TIME_STEP
        position.x = clamp(
                position.x,
                position_x_min,
                position_x_max)
        position = Sc.geometry.project_shape_onto_surface(
                position,
                movement_params.collider,
                start.surface,
                true)
        previous_velocity = velocity
        velocity += acceleration * Time.PHYSICS_TIME_STEP
        velocity.x = clamp(
                velocity.x,
                velocity_x_min,
                velocity_x_max)
        
        if is_next_neighbor_concave:
            # This prevents collisions with concave next neighbors
            # (which can form tight cusps).
            var override: Vector2 = \
                    Sc.geometry.project_away_from_concave_neighbor(
                        position,
                        next_neighbor,
                        next_neighbor_normal_side_override,
                        movement_params.collider)
            if override != Vector2.INF:
                ran_into_concave_next_neighbor = true
                position = override
                if frame_index + position_duplication_count < frame_count:
                    positions[frame_index] = position
                    velocities[frame_index] = velocity
                break
    
    # In case the movement reached the destination before the expected number
    # of frames, we remove any trailing frames.
    positions.resize(frame_index)
    velocities.resize(frame_index)
    
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
    
    trajectory.collided_early = ran_into_concave_next_neighbor
    trajectory.position_duplication_start_index = \
            position_duplication_start_index
    
    return trajectory


func _calculate_is_pressing_forward(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        is_pressing_left: bool) -> bool:
    if start.surface.side != SurfaceSide.FLOOR:
        return true
    
    var displacement := end.target_point - start.target_point
    if displacement.x == 0.0:
        return false
    
    return is_pressing_left == (displacement.x < 0)


func _calculate_is_pressing_left(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        includes_deceleration_at_end: bool) -> bool:
    var displacement := end.target_point - start.target_point
    var is_displacement_leftward := displacement.x < 0.0
    match start.surface.side:
        SurfaceSide.FLOOR:
            if !includes_deceleration_at_end:
                return is_displacement_leftward
            if displacement.x == 0.0:
                return velocity_start.x > 0.0
            var stopping_distance_from_start_speed := \
                    MovementUtils.calculate_distance_to_stop_from_friction(
                        movement_params,
                        start.surface.properties,
                        velocity_start.x)
            var is_pressing_forward := \
                    stopping_distance_from_start_speed < abs(displacement.x)
            return is_pressing_forward == is_displacement_leftward
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            return false
        SurfaceSide.CEILING:
            return is_displacement_leftward
        _:
            Sc.logger.error()
            return false


# Calculate the distance from the end position at which the move button should
# be released, so that the character comes to rest at the desired end position
# after decelerating due to friction (and with accelerating, or coasting at
# max-speed, until starting deceleration).
func _calculate_stopping_distance(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        is_pressing_left: bool,
        is_pressing_forward: bool,
        includes_deceleration_at_end: bool) -> float:
    var displacement := end.target_point - start.target_point
    
    # TODO: Add support for acceleration and friction along walls and ceilings.
    if end.surface.side != SurfaceSide.FLOOR or \
            !includes_deceleration_at_end:
        return 0.0
    
    if is_pressing_forward:
        return MovementUtils \
                .calculate_distance_to_stop_from_friction_with_forward_acceleration_to_non_max_speed(
                    movement_params,
                    start.surface.properties,
                    velocity_start.x,
                    displacement.x)
    else:
        return MovementUtils \
                .calculate_distance_to_stop_from_friction_with_some_backward_acceleration(
                    movement_params,
                    start.surface.properties,
                    velocity_start.x,
                    displacement.x)


func _calculate_release_time(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        stopping_distance: float,
        is_pressing_left: bool,
        is_pressing_forward: bool,
        is_degenerate: bool) -> float:
    if is_degenerate:
        return 0.0
    
    var displacement := end.target_point - start.target_point
    
    match start.side:
        SurfaceSide.FLOOR:
            var acceleration_magnitude := MovementUtils \
                    .get_walking_acceleration_with_friction_magnitude(
                        movement_params,
                        start.surface.properties)
            var acceleration_x := \
                    -acceleration_magnitude if \
                    is_pressing_left else \
                    acceleration_magnitude
            var max_horizontal_speed := \
                    movement_params.get_max_surface_speed() * \
                    start.surface.properties.speed_multiplier
            var has_enough_time_to_decelerate_to_zero := \
                    is_pressing_forward or \
                    !is_inf(stopping_distance)
            var input_displacement: float
            if has_enough_time_to_decelerate_to_zero:
                input_displacement = \
                        displacement.x - stopping_distance if \
                        displacement.x > 0.0 else \
                        displacement.x + stopping_distance
            else:
                input_displacement = displacement.x
            # -   If pressing forward, there could be backward movement.
            # -   So if pressing forward, we use the later possible duration.
            var returns_lower_result := !is_pressing_forward
            
            return MovementUtils.calculate_duration_for_displacement(
                    input_displacement,
                    velocity_start.x,
                    acceleration_x,
                    max_horizontal_speed,
                    returns_lower_result)
            
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var is_climbing_upward := displacement.y < 0
            return MovementUtils.calculate_time_to_climb(
                    abs(displacement.y),
                    is_climbing_upward,
                    start.surface,
                    movement_params)
        SurfaceSide.CEILING:
            return MovementUtils.calculate_time_to_crawl_on_ceiling(
                    abs(displacement.x),
                    start.surface,
                    movement_params)
        _:
            Sc.logger.error()
            return INF


func _calculate_release_position(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        release_time: float,
        is_pressing_left: bool) -> Vector2:
    var displacement := end.target_point - start.target_point
    var acceleration_magnitude := MovementUtils \
            .get_walking_acceleration_with_friction_magnitude(
                movement_params,
                start.surface.properties)
    var acceleration_x := \
            -acceleration_magnitude if \
            is_pressing_left else \
            acceleration_magnitude
    var max_horizontal_speed := \
            movement_params.get_max_surface_speed() * \
            start.surface.properties.speed_multiplier
    var displacement_x := MovementUtils.calculate_displacement_for_duration(
            release_time,
            velocity_start.x,
            acceleration_x,
            max_horizontal_speed)
    var position_x := start.target_point.x + displacement_x
    return Sc.geometry.project_shape_onto_surface(
            Vector2(position_x, 0.0),
            movement_params.collider,
            start.surface,
            true)


func _calculate_release_velocity(
        movement_params: MovementParameters,
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        velocity_start: Vector2,
        release_time: float,
        is_pressing_left: bool) -> Vector2:
    var displacement := end.target_point - start.target_point
    var acceleration_magnitude := MovementUtils \
            .get_walking_acceleration_with_friction_magnitude(
                movement_params,
                start.surface.properties)
    var acceleration_x := \
            -acceleration_magnitude if \
            is_pressing_left else \
            acceleration_magnitude
    var max_horizontal_speed := \
            movement_params.get_max_surface_speed() * \
            start.surface.properties.speed_multiplier
    var velocity_x := velocity_start.x + acceleration_x * release_time
    velocity_x = clamp(
            velocity_x,
            -max_horizontal_speed,
            max_horizontal_speed)
    return Vector2(velocity_x, 0.0)
