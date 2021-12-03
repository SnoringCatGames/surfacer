class_name FallFromFloorCalculator
extends EdgeCalculator


const NAME := "FallFromFloorCalculator"
const EDGE_TYPE := EdgeType.FALL_FROM_FLOOR_EDGE
const IS_A_JUMP_CALCULATOR := false
const IS_GRAPHABLE := true

const EXTRA_FALL_OFF_POSITION_MARGIN := 2.0


func _init().(
        NAME,
        EDGE_TYPE,
        IS_A_JUMP_CALCULATOR,
        IS_GRAPHABLE) -> void:
    pass


func get_can_traverse_from_surface(
        surface: Surface,
        collision_params: CollisionCalcParams) -> bool:
    return surface != null and \
            collision_params.surfaces_set.has(surface) and \
            surface.side == SurfaceSide.FLOOR and \
            (surface.counter_clockwise_convex_neighbor != null or \
            surface.clockwise_convex_neighbor != null)


func get_all_inter_surface_edges_from_surface(
        inter_surface_edges_results: Array,
        collision_params: CollisionCalcParams,
        origin_surface: Surface,
        surfaces_in_fall_range_set: Dictionary,
        surfaces_in_jump_range_set: Dictionary) -> void:
    if origin_surface.counter_clockwise_convex_neighbor != null:
        # Calculating the fall-off state for the left edge of the floor.
        _get_all_edges_from_one_side(
                inter_surface_edges_results,
                null,
                collision_params,
                surfaces_in_fall_range_set,
                origin_surface,
                true,
                null,
                true)
    
    if origin_surface.clockwise_convex_neighbor != null:
        # Calculating the fall-off state for the right edge of the floor.
        _get_all_edges_from_one_side(
                inter_surface_edges_results,
                null,
                collision_params,
                surfaces_in_fall_range_set,
                origin_surface,
                false,
                null,
                true)
    
    InterSurfaceEdgesResult.merge_results_with_matching_destination_surfaces(
            inter_surface_edges_results)


func calculate_edge(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        velocity_start := Vector2.INF,
        needs_extra_jump_duration := false,
        needs_extra_wall_land_horizontal_speed := false,
        basis_edge: EdgeAttempt = null) -> Edge:
    var inter_surface_edges_results := []
    var surfaces_in_fall_range_set := {}
    var origin_surface := position_start.surface
    var falls_on_left_side: bool = \
            basis_edge.extra_flag_metadata if \
            basis_edge is FailedEdgeAttempt else \
            basis_edge.falls_on_left_side
    edge_result_metadata = \
            edge_result_metadata if \
            edge_result_metadata != null else \
            EdgeCalcResultMetadata.new(false, false)
    
    _get_all_edges_from_one_side(
            inter_surface_edges_results,
            edge_result_metadata,
            collision_params,
            surfaces_in_fall_range_set,
            origin_surface,
            falls_on_left_side,
            position_end,
            edge_result_metadata.records_profile,
            needs_extra_wall_land_horizontal_speed)
    
    if !inter_surface_edges_results.empty() and \
            !inter_surface_edges_results[0].valid_edges.empty():
        return inter_surface_edges_results[0].valid_edges[0]
    else:
        return null


func optimize_edge_land_position_for_path(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        edge_index: int,
        edge: Edge,
        next_edge: IntraSurfaceEdge) -> void:
    assert(edge is FallFromFloorEdge)
    
    EdgeCalculator.optimize_edge_land_position_for_path_helper(
            collision_params,
            path,
            edge_index,
            edge,
            next_edge,
            self)


func _get_all_edges_from_one_side(
        inter_surface_edges_results: Array,
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        surfaces_in_fall_range_set: Dictionary,
        origin_surface: Surface,
        falls_on_left_side: bool,
        exclusive_land_position: PositionAlongSurface,
        records_profile: bool,
        needs_extra_wall_land_horizontal_speed := false) -> void:
    assert(!needs_extra_wall_land_horizontal_speed or \
            exclusive_land_position != null)
    
    Sc.profiler.start(
            "fall_from_floor_walk_to_fall_off_point_calculation",
            collision_params.thread_id)
    
    var debug_params := collision_params.debug_params
    var movement_params := collision_params.movement_params
    var new_inter_surface_edges_results_start_index := \
            inter_surface_edges_results.size()
    
    var edge_point := \
            origin_surface.first_point if \
            falls_on_left_side else \
            origin_surface.last_point
    
    var position_start := PositionAlongSurface.new()
    position_start.match_surface_target_and_collider(
            origin_surface,
            edge_point,
            movement_params.collider,
            false,
            true,
            true)
    if !position_start.is_valid:
        Sc.profiler.stop(
                "fall_from_floor_walk_to_fall_off_point_calculation",
                collision_params.thread_id,
                records_profile)
        return
    
    ###########################################################################
    # Allow for debug mode to limit the scope of what's calculated.
    if EdgeCalculator.should_skip_edge_calculation(
            debug_params,
            position_start,
            null,
            null):
        Sc.profiler.stop(
                "fall_from_floor_walk_to_fall_off_point_calculation",
                collision_params.thread_id,
                records_profile)
        return
    ###########################################################################
    
    var position_fall_off := _calculate_character_center_at_fall_off_point(
            edge_point,
            falls_on_left_side,
            movement_params.fall_from_floor_corner_calc_shape)
    
    var position_fall_off_wrapper := PositionAlongSurfaceFactory \
            .create_position_from_unmodified_target_point(
                    position_fall_off,
                    origin_surface)
    
    var displacement_from_start_to_fall_off := \
            position_fall_off - position_start.target_point
    
    var acceleration := \
            -movement_params.walk_acceleration if \
            falls_on_left_side else \
            movement_params.walk_acceleration
    
    var surface_end_velocity_start: Vector2 = \
            JumpLandPositionsUtils.get_velocity_start(
                    movement_params,
                    origin_surface,
                    false,
                    falls_on_left_side)
    
    var velocity_x_start := surface_end_velocity_start.x
    var max_horizontal_speed := movement_params.get_max_surface_speed()
    
    var velocity_x_fall_off: float = \
            MovementUtils.calculate_velocity_end_for_displacement(
                displacement_from_start_to_fall_off.x,
                velocity_x_start,
                acceleration,
                max_horizontal_speed)
    
    var time_fall_off: float = \
            MovementUtils.calculate_duration_for_displacement(
                displacement_from_start_to_fall_off.x,
                velocity_x_start,
                acceleration,
                max_horizontal_speed)
    
    var fall_off_point_velocity_start := Vector2(velocity_x_fall_off, 0.0)
    
    Sc.profiler.stop(
            "fall_from_floor_walk_to_fall_off_point_calculation",
            collision_params.thread_id,
            records_profile)
    
    if exclusive_land_position != null:
        assert(edge_result_metadata != null)
        
        var jump_land_positions := JumpLandPositions.new(
                position_start,
                exclusive_land_position,
                surface_end_velocity_start,
                false,
                needs_extra_wall_land_horizontal_speed,
                false)
        var inter_surface_edges_result := InterSurfaceEdgesResult.new(
                origin_surface,
                exclusive_land_position.surface,
                edge_type,
                [jump_land_positions])
        inter_surface_edges_results.push_back(inter_surface_edges_result)
        
        var calc_result: EdgeCalcResult = \
                FallMovementUtils.find_landing_trajectory_between_positions(
                        edge_result_metadata,
                        collision_params,
                        position_fall_off_wrapper,
                        exclusive_land_position,
                        fall_off_point_velocity_start,
                        false,
                        needs_extra_wall_land_horizontal_speed)
        if calc_result != null:
            assert(EdgeCalcResultType.get_is_valid(
                    edge_result_metadata.edge_calc_result_type))
            inter_surface_edges_result.edge_calc_results.push_back(calc_result)
        else:
            assert(!EdgeCalcResultType.get_is_valid(
                    edge_result_metadata.edge_calc_result_type))
            var failed_attempt := FailedEdgeAttempt.new(
                    jump_land_positions,
                    edge_result_metadata,
                    self)
            failed_attempt.extra_flag_metadata = falls_on_left_side
            inter_surface_edges_result.failed_edge_attempts.push_back(
                    failed_attempt)
    else:
        var new_results_count := \
                FallMovementUtils.find_landing_trajectories_to_any_surface(
                        inter_surface_edges_results,
                        collision_params,
                        surfaces_in_fall_range_set,
                        position_fall_off_wrapper,
                        fall_off_point_velocity_start,
                        false,
                        self,
                        records_profile)
        for i in new_results_count:
            var result: InterSurfaceEdgesResult = \
                    inter_surface_edges_results[-new_results_count + i]
            for failed_attempt in result.failed_edge_attempts:
                failed_attempt.extra_flag_metadata = falls_on_left_side
    
    for i in range(
            new_inter_surface_edges_results_start_index,
            inter_surface_edges_results.size()):
        var inter_surface_edges_result: InterSurfaceEdgesResult = \
                        inter_surface_edges_results[i]
        for calc_result in inter_surface_edges_result.edge_calc_results:
            var position_end: PositionAlongSurface \
                        = calc_result.edge_calc_params.destination_position
            
            var instructions := EdgeInstructionsUtils \
                    .convert_calculation_steps_to_movement_instructions(
                            records_profile,
                            collision_params,
                            calc_result,
                            false,
                            position_end.side)
            
            var trajectory := EdgeTrajectoryUtils \
                    .calculate_trajectory_from_calculation_steps(
                            records_profile,
                            collision_params,
                            calc_result,
                            instructions)
            
            _prepend_walk_to_fall_off_portion(
                    position_start,
                    position_end,
                    edge_point,
                    velocity_x_start,
                    time_fall_off,
                    instructions,
                    trajectory,
                    movement_params,
                    falls_on_left_side)
            
            var velocity_end: Vector2 = \
                    calc_result.horizontal_steps.back().velocity_step_end
            
            var edge := FallFromFloorEdge.new(
                    self,
                    position_start,
                    position_end,
                    surface_end_velocity_start,
                    velocity_end,
                    trajectory.distance_from_continuous_trajectory,
                    instructions.duration,
                    calc_result.edge_calc_params \
                            .needs_extra_wall_land_horizontal_speed,
                    movement_params,
                    instructions,
                    trajectory,
                    calc_result.edge_calc_result_type,
                    falls_on_left_side,
                    position_fall_off_wrapper,
                    time_fall_off)
            inter_surface_edges_result.valid_edges.push_back(edge)


static func _prepend_walk_to_fall_off_portion(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        edge_point: Vector2,
        velocity_x_start: float,
        time_fall_off: float,
        instructions: EdgeInstructions,
        trajectory: EdgeTrajectory,
        movement_params: MovementParameters,
        falls_on_left_side: bool) -> void:
    var frame_count_before_fall_off := \
            floor(time_fall_off / Time.PHYSICS_TIME_STEP)
    time_fall_off = \
            frame_count_before_fall_off * Time.PHYSICS_TIME_STEP + \
            Sc.geometry.FLOAT_EPSILON
    
    # Increment instruction times.
    
    for instruction in instructions.instructions:
        instruction.time += time_fall_off
    
    instructions.duration += time_fall_off
    
    # Insert the walk-to-fall-off instructions.
    
    var sideways_input_key := \
            "ml" if \
            falls_on_left_side else \
            "mr"
    var outward_press := EdgeInstruction.new(
            sideways_input_key,
            0.0,
            true)
    var outward_release := EdgeInstruction.new(
            sideways_input_key,
            time_fall_off - 0.0001,
            false)
    instructions.instructions.push_front(outward_release)
    instructions.instructions.push_front(outward_press)
    
    # Insert frame state for the walk-to-fall-off portion of the trajectory.
    
    if !movement_params.includes_discrete_trajectory_state and \
            !movement_params.includes_continuous_trajectory_positions and \
            !movement_params.includes_continuous_trajectory_velocities:
        return
    
    if movement_params.includes_discrete_trajectory_state:
        var walking_and_falling_frame_discrete_positions_from_test = \
                PoolVector2Array()
        walking_and_falling_frame_discrete_positions_from_test.resize(
                frame_count_before_fall_off)
        walking_and_falling_frame_discrete_positions_from_test.append_array(
                trajectory.frame_discrete_positions_from_test)
        trajectory.frame_discrete_positions_from_test = \
                walking_and_falling_frame_discrete_positions_from_test
    
    if movement_params.includes_continuous_trajectory_positions:
        var walking_and_falling_frame_continuous_positions_from_steps = \
                PoolVector2Array()
        walking_and_falling_frame_continuous_positions_from_steps.resize(
                frame_count_before_fall_off)
        walking_and_falling_frame_continuous_positions_from_steps \
                .append_array(
                trajectory.frame_continuous_positions_from_steps)
        trajectory.frame_continuous_positions_from_steps = \
                walking_and_falling_frame_continuous_positions_from_steps
    
    if movement_params.includes_continuous_trajectory_velocities:
        var walking_and_falling_frame_continuous_velocities_from_steps = \
                PoolVector2Array()
        walking_and_falling_frame_continuous_velocities_from_steps.resize(
                frame_count_before_fall_off)
        walking_and_falling_frame_continuous_velocities_from_steps \
                .append_array(
                trajectory.frame_continuous_velocities_from_steps)
        trajectory.frame_continuous_velocities_from_steps = \
                walking_and_falling_frame_continuous_velocities_from_steps
    
    var acceleration_x := \
            -movement_params.walk_acceleration if \
            falls_on_left_side else \
            movement_params.walk_acceleration
    var acceleration := Vector2(acceleration_x, 0.0)
    
    var current_frame_position := start.target_point
    var current_frame_velocity := Vector2(velocity_x_start, 0.0)
    
    for frame_index in frame_count_before_fall_off:
        if movement_params.includes_discrete_trajectory_state:
            trajectory.frame_discrete_positions_from_test[frame_index] = \
                    current_frame_position
        if movement_params.includes_continuous_trajectory_positions:
            trajectory.frame_continuous_positions_from_steps[frame_index] = \
                    current_frame_position
        if movement_params.includes_continuous_trajectory_velocities:
            trajectory.frame_continuous_velocities_from_steps[frame_index] = \
                    current_frame_velocity
        
        current_frame_position.x = \
                current_frame_position.x + \
                current_frame_velocity.x * Time.PHYSICS_TIME_STEP
        current_frame_position = Sc.geometry \
                .project_shape_onto_convex_corner_preserving_tangent_position( \
                        current_frame_position,
                        movement_params.fall_from_floor_corner_calc_shape,
                        start.surface,
                        null)
        
        current_frame_velocity += acceleration * Time.PHYSICS_TIME_STEP
        current_frame_velocity = \
                MovementUtils.clamp_horizontal_velocity_to_max_default(
                        movement_params,
                        current_frame_velocity)
    
    # Update the trajectory distance.
    trajectory.distance_from_continuous_trajectory = \
            EdgeTrajectoryUtils.sum_distance_between_frames(
                    trajectory.frame_continuous_positions_from_steps)


static func _calculate_character_center_at_fall_off_point(
        edge_point: Vector2,
        falls_on_left_side: bool,
        collider: RotatedShape) -> Vector2:
    var right_side_fall_off_displacement_x: float
    var fall_off_displacement_y: float
    
    if collider.shape is CircleShape2D:
        right_side_fall_off_displacement_x = collider.shape.radius
        fall_off_displacement_y = 0.0
        
    elif collider.shape is CapsuleShape2D:
        if collider.is_rotated_90_degrees:
            right_side_fall_off_displacement_x = \
                    collider.shape.radius + collider.shape.height * 0.5
            fall_off_displacement_y = 0.0
        else:
            right_side_fall_off_displacement_x = collider.shape.radius
            fall_off_displacement_y = -collider.shape.height * 0.5
        
    elif collider.shape is RectangleShape2D:
        if collider.is_rotated_90_degrees:
            right_side_fall_off_displacement_x = collider.shape.extents.y
            fall_off_displacement_y = -collider.shape.extents.x
        else:
            right_side_fall_off_displacement_x = collider.shape.extents.x
            fall_off_displacement_y = -collider.shape.extents.y
        
    else:
        Sc.logger.error((
                "Invalid Shape2D provided for " +
                "_calculate_character_center_at_fall_off_point: %s. " +
                "The supported shapes are: CircleShape2D, CapsuleShape2D, " +
                "RectangleShape2D.") % \
                collider.shape)
    
    right_side_fall_off_displacement_x += EXTRA_FALL_OFF_POSITION_MARGIN
    
    return edge_point + Vector2(
            -right_side_fall_off_displacement_x if \
                    falls_on_left_side else \
                    right_side_fall_off_displacement_x,
            fall_off_displacement_y)
