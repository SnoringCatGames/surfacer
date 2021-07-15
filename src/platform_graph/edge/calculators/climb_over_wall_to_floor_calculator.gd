class_name ClimbOverWallToFloorCalculator
extends EdgeCalculator


const NAME := "ClimbOverWallToFloorCalculator"
const EDGE_TYPE := EdgeType.CLIMB_OVER_WALL_TO_FLOOR_EDGE
const IS_A_JUMP_CALCULATOR := false


func _init().(
        NAME,
        EDGE_TYPE,
        IS_A_JUMP_CALCULATOR) -> void:
    pass


func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and \
            ((surface.side == SurfaceSide.LEFT_WALL and \
                    surface.counter_clockwise_convex_neighbor != null) or \
            (surface.side == SurfaceSide.RIGHT_WALL and \
                    surface.clockwise_convex_neighbor != null))


func get_all_inter_surface_edges_from_surface(
        inter_surface_edges_results: Array,
        collision_params: CollisionCalcParams,
        origin_surface: Surface,
        surfaces_in_fall_range_set: Dictionary,
        surfaces_in_jump_range_set: Dictionary) -> void:
    var movement_params := collision_params.movement_params
    
    var upper_neighbor_floor: Surface
    var wall_top_point: Vector2
    var floor_edge_point: Vector2
    
    if origin_surface.side == SurfaceSide.LEFT_WALL:
        upper_neighbor_floor = origin_surface.counter_clockwise_convex_neighbor
        wall_top_point = origin_surface.first_point
        floor_edge_point = upper_neighbor_floor.last_point
        
    elif origin_surface.side == SurfaceSide.RIGHT_WALL:
        upper_neighbor_floor = origin_surface.clockwise_convex_neighbor
        wall_top_point = origin_surface.last_point
        floor_edge_point = upper_neighbor_floor.first_point
    
    if upper_neighbor_floor == null:
        # There is no floor surface to climb up to.
        return
    
    var start_position := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    wall_top_point,
                    origin_surface,
                    movement_params.collider_half_width_height)
    var end_position := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    floor_edge_point,
                    upper_neighbor_floor,
                    movement_params.collider_half_width_height)
    
    ###########################################################################
    # Allow for debug mode to limit the scope of what's calculated.
    if EdgeCalculator.should_skip_edge_calculation(
            collision_params.debug_params,
            start_position,
            end_position,
            null):
        return
    ###########################################################################
    
    var jump_land_positions := JumpLandPositions.new(
            start_position,
            end_position,
            Vector2.ZERO,
            false,
            false,
            false)
    var inter_surface_edges_result := InterSurfaceEdgesResult.new(
            origin_surface,
            upper_neighbor_floor,
            edge_type,
            [jump_land_positions])
    inter_surface_edges_results.push_back(inter_surface_edges_result)
    
    var edge := calculate_edge(
            null,
            collision_params,
            start_position,
            end_position)
    inter_surface_edges_result.valid_edges.push_back(edge)


func calculate_edge(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        velocity_start := Vector2.INF,
        needs_extra_jump_duration := false,
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    if edge_result_metadata != null:
        edge_result_metadata.edge_calc_result_type = \
                EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP
        edge_result_metadata.waypoint_validity = \
                WaypointValidity.WAYPOINT_VALID
    var trajectory := _calculate_trajectory(
            collision_params.movement_params,
            position_start,
            position_end)
    return ClimbOverWallToFloorEdge.new(
            self,
            position_start,
            position_end,
            collision_params.movement_params,
            trajectory)


static func _calculate_trajectory(
        movement_params: MovementParams,
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> EdgeTrajectory:
    var is_left_wall := start.surface.side == SurfaceSide.LEFT_WALL
    var edge_point := \
            start.surface.first_point if \
            is_left_wall else \
            start.surface.last_point
    
    var distance_y := end.target_point.y - start.target_point.y
    var duration := MovementUtils.calculate_time_to_climb(
            distance_y,
            true,
            movement_params)
    
    var frame_count := ceil(duration / Time.PHYSICS_TIME_STEP)
    
    # Insert frame state for the walk-to-fall-off portion of the trajectory.
    
    if !movement_params.includes_discrete_trajectory_state and \
            !movement_params \
                    .includes_continuous_trajectory_positions and \
            !movement_params.includes_continuous_trajectory_velocities:
        return EdgeTrajectory.new(
                PoolVector2Array(),
                PoolVector2Array(),
                [],
                Sc.geometry.calculate_manhattan_distance(
                        start.target_point, end.target_point))
    
    var frame_discrete_positions_from_test: PoolVector2Array
    if movement_params.includes_discrete_trajectory_state:
        frame_discrete_positions_from_test = PoolVector2Array()
        frame_discrete_positions_from_test.resize(frame_count)
    
    var frame_continuous_positions_from_steps: PoolVector2Array
    if movement_params.includes_continuous_trajectory_positions:
        frame_continuous_positions_from_steps = PoolVector2Array()
        frame_continuous_positions_from_steps.resize(frame_count)
    
    var frame_continuous_velocities_from_steps: PoolVector2Array
    if movement_params.includes_continuous_trajectory_velocities:
        frame_continuous_velocities_from_steps = PoolVector2Array()
        frame_continuous_velocities_from_steps.resize(frame_count)
    
    var velocity := Vector2(
            PlayerActionHandler.MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION,
            movement_params.climb_up_speed)
    
    var current_frame_position := start.target_point
    
    for frame_index in frame_count:
        if movement_params.includes_discrete_trajectory_state:
            frame_discrete_positions_from_test[frame_index] = \
                    current_frame_position
        if movement_params.includes_continuous_trajectory_positions:
            frame_continuous_positions_from_steps[frame_index] = \
                    current_frame_position
        if movement_params.includes_continuous_trajectory_velocities:
            frame_continuous_velocities_from_steps[frame_index] = \
                    velocity
        
        var frame_position_y := \
                current_frame_position.y + \
                velocity.y * Time.PHYSICS_TIME_STEP
        var distance_past_edge := start.target_point.y - frame_position_y
        var frame_position_x := \
                edge_point.x + \
                _calculate_displacement_x_for_vertical_distance_past_edge(
                        distance_past_edge,
                        is_left_wall,
                        movement_params.climb_over_wall_corner_calc_shape,
                        movement_params \
                                .climb_over_wall_corner_calc_shape_rotation)
        
        current_frame_position.x = frame_position_x
        current_frame_position.y = frame_position_y
    
    
    var distance_from_continuous_trajectory := EdgeTrajectoryUtils \
            .sum_distance_between_frames(frame_continuous_positions_from_steps)
    var trajectory := EdgeTrajectory.new(
            frame_continuous_positions_from_steps,
            frame_continuous_velocities_from_steps,
            [],
            distance_from_continuous_trajectory)
    trajectory.frame_discrete_positions_from_test = \
            frame_discrete_positions_from_test
    return trajectory


static func _calculate_displacement_x_for_vertical_distance_past_edge( \
        distance_past_edge: float,
        is_left_wall: bool,
        collider_shape: Shape2D,
        collider_rotation: float) -> float:
    var is_rotated_90_degrees = \
            abs(fmod(collider_rotation + PI * 2, PI) - PI / 2) < \
            Sc.geometry.FLOAT_EPSILON
    
    if collider_shape is CircleShape2D:
        if distance_past_edge >= collider_shape.radius:
            return 0.0
        else:
            return _calculate_circular_displacement_x_for_vertical_distance_past_edge(
                    distance_past_edge,
                    collider_shape.radius,
                    is_left_wall)
        
    elif collider_shape is CapsuleShape2D:
        if is_rotated_90_degrees:
            var half_height_offset: float = \
                    collider_shape.height / 2.0 if \
                    is_left_wall else \
                    -collider_shape.height / 2.0
            return _calculate_circular_displacement_x_for_vertical_distance_past_edge(
                    distance_past_edge,
                    collider_shape.radius,
                    is_left_wall) + half_height_offset
        else:
            distance_past_edge -= collider_shape.height / 2.0
            if distance_past_edge <= 0:
                # Treat the same as a rectangle.
                return collider_shape.radius if \
                        is_left_wall else \
                        -collider_shape.radius
            else:
                # Treat the same as an offset circle.
                return _calculate_circular_displacement_x_for_vertical_distance_past_edge(
                        distance_past_edge,
                        collider_shape.radius,
                        is_left_wall)
        
    elif collider_shape is RectangleShape2D:
        if is_rotated_90_degrees:
            return collider_shape.extents.y if \
                    is_left_wall else \
                    -collider_shape.extents.y
        else:
            return collider_shape.extents.x if \
                    is_left_wall else \
                    -collider_shape.extents.x
        
    else:
        Sc.logger.error((
                "Invalid Shape2D provided for " +
                "_calculate_displacement_x_for_vertical_distance_past_edge: %s. " +
                "The supported shapes are: CircleShape2D, CapsuleShape2D, " +
                "RectangleShape2D.") % \
                collider_shape)
        return INF


static func _calculate_circular_displacement_x_for_vertical_distance_past_edge(
        distance_past_edge: float,
        radius: float,
        is_left_wall: bool) -> float:
    var distance_x := \
            0.0 if \
            distance_past_edge >= radius else \
            sqrt(radius * radius - distance_past_edge * distance_past_edge)
    return distance_x if \
            is_left_wall else \
            -distance_x
