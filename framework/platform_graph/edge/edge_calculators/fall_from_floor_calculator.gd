extends EdgeMovementCalculator
class_name FallFromFloorCalculator

const NAME := "FallFromFloorCalculator"
const EDGE_TYPE := EdgeType.FALL_FROM_FLOOR_EDGE
const IS_A_JUMP_CALCULATOR := false

const EXTRA_FALL_OFF_POSITION_MARGIN := 2.0

func _init().( \
        NAME, \
        EDGE_TYPE, \
        IS_A_JUMP_CALCULATOR) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and \
            surface.side == SurfaceSide.FLOOR and \
            (surface.counter_clockwise_concave_neighbor == null or \
            surface.clockwise_concave_neighbor == null)

func get_all_inter_surface_edges_from_surface( \
        edges_result: Array, \
        failed_edge_attempts_result: Array, \
        collision_params: CollisionCalcParams, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    if origin_surface.counter_clockwise_concave_neighbor == null:
        # Calculating the fall-off state for the left edge of the floor.
        _get_all_edges_from_one_side( \
                collision_params, \
                edges_result, \
                surfaces_in_fall_range_set, \
                origin_surface, \
                true, \
                null)
    
    if origin_surface.clockwise_concave_neighbor == null:
        # Calculating the fall-off state for the right edge of the floor.
        _get_all_edges_from_one_side( \
                collision_params, \
                edges_result, \
                surfaces_in_fall_range_set, \
                origin_surface, \
                false, \
                null)

func calculate_edge( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: PositionAlongSurface, \
        velocity_start := Vector2.INF, \
        needs_extra_jump_duration := false, \
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    var edges_result := []
    var surfaces_in_fall_range_set := {}
    var origin_surface := position_start.surface
    var falls_on_left_side := position_start.target_point == origin_surface.first_point
    
    _get_all_edges_from_one_side( \
            collision_params, \
            edges_result, \
            surfaces_in_fall_range_set, \
            origin_surface, \
            falls_on_left_side, \
            position_end, \
            needs_extra_wall_land_horizontal_speed)
    
    if edges_result.size() > 0:
        return edges_result[0]
    else:
        return null

func optimize_edge_land_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        edge: Edge, \
        next_edge: IntraSurfaceEdge) -> void:
    assert(edge is FallFromFloorEdge)
    
    EdgeMovementCalculator.optimize_edge_land_position_for_path_helper( \
            collision_params, \
            path, \
            edge_index, \
            edge, \
            next_edge, \
            self)

func _get_all_edges_from_one_side( \
        collision_params: CollisionCalcParams, \
        edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, \
        origin_surface: Surface, \
        falls_on_left_side: bool, \
        exclusive_land_position: PositionAlongSurface, \
        needs_extra_wall_land_horizontal_speed := false) -> void:
    assert(!needs_extra_wall_land_horizontal_speed or exclusive_land_position != null)
    
    var debug_params := collision_params.debug_params
    var movement_params := collision_params.movement_params
    
    var edge_point := \
            origin_surface.first_point if \
            falls_on_left_side else \
            origin_surface.last_point
    
    var position_start := PositionAlongSurface.new()
    position_start.match_surface_target_and_collider( \
            origin_surface, \
            edge_point, \
            movement_params.collider_half_width_height, \
            true, \
            false)
    
    ###################################################################################
    # Allow for debug mode to limit the scope of what's calculated.
    if EdgeMovementCalculator.should_skip_edge_calculation( \
            debug_params, \
            position_start, \
            null):
        return
    ###################################################################################
    
    var position_fall_off := _calculate_player_center_at_fall_off_point( \
            edge_point, \
            falls_on_left_side, \
            movement_params.collider_shape, \
            movement_params.collider_rotation)
    
    var position_fall_off_wrapper := MovementUtils.create_position_from_target_point( \
            position_fall_off, \
            origin_surface, \
            movement_params.collider_half_width_height)
    
    var displacement_from_start_to_fall_off := position_fall_off - position_start.target_point
    
    var acceleration := \
            -movement_params.walk_acceleration if \
            falls_on_left_side else \
            movement_params.walk_acceleration
    
    var surface_end_velocity_start: Vector2 = JumpLandPositionsUtils.get_velocity_start( \
            movement_params, \
            origin_surface, \
            is_a_jump_calculator, \
            falls_on_left_side)
    
    var velocity_x_start := surface_end_velocity_start.x
    
    var velocity_x_fall_off: float = MovementUtils.calculate_velocity_end_for_displacement( \
            displacement_from_start_to_fall_off.x, \
            velocity_x_start, \
            acceleration, \
            movement_params.max_horizontal_speed_default)
    
    var time_fall_off: float = MovementUtils.calculate_duration_for_displacement( \
            displacement_from_start_to_fall_off.x, \
            velocity_x_start, \
            acceleration, \
            movement_params.max_horizontal_speed_default)
    
    var fall_off_point_velocity_start := Vector2(velocity_x_fall_off, 0.0)
    
    var landing_trajectories: Array
    if exclusive_land_position != null:
        var calc_result: EdgeCalcResult = \
                FallMovementUtils.find_landing_trajectory_between_positions( \
                        null, \
                        collision_params, \
                        position_fall_off_wrapper, \
                        exclusive_land_position, \
                        fall_off_point_velocity_start, \
                        needs_extra_wall_land_horizontal_speed)
        if calc_result != null:
            landing_trajectories = [calc_result]
        else:
            landing_trajectories = []
    else:
        landing_trajectories = FallMovementUtils.find_landing_trajectories_to_any_surface( \
                collision_params, \
                surfaces_in_fall_range_set, \
                position_fall_off_wrapper, \
                fall_off_point_velocity_start)
    
    var position_end: PositionAlongSurface
    var instructions: MovementInstructions
    var trajectory: MovementTrajectory
    var velocity_end: Vector2
    var edge: FallFromFloorEdge
    
    for calc_result in landing_trajectories:
        position_end = calc_result.edge_calc_params.destination_position
        
        instructions = \
                MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
                        calc_result, \
                        false, \
                        position_end.surface.side)
        
        trajectory = MovementTrajectoryUtils.calculate_trajectory_from_calculation_steps( \
                calc_result, \
                instructions)
        
        _prepend_walk_to_fall_off_portion( \
                position_start, \
                position_end, \
                velocity_x_start, \
                time_fall_off, \
                instructions, \
                trajectory, \
                movement_params, \
                falls_on_left_side)
        
        velocity_end = calc_result.horizontal_steps.back().velocity_step_end
        
        edge = FallFromFloorEdge.new( \
                self, \
                position_start, \
                position_end, \
                fall_off_point_velocity_start, \
                velocity_end, \
                calc_result.edge_calc_params.needs_extra_wall_land_horizontal_speed, \
                movement_params, \
                instructions, \
                trajectory, \
                falls_on_left_side, \
                position_fall_off_wrapper)
        edges_result.push_back(edge)

static func _calculate_player_center_at_fall_off_point( \
        edge_point: Vector2, \
        falls_on_left_side: bool, \
        collider_shape: Shape2D, \
        collider_rotation: float) -> Vector2:
    var is_rotated_90_degrees = \
            abs(fmod(collider_rotation + PI * 2, PI) - PI / 2) < Geometry.FLOAT_EPSILON
    # Ensure that collision boundaries are only ever axially aligned.
    assert(is_rotated_90_degrees or abs(collider_rotation) < Geometry.FLOAT_EPSILON)
    
    var right_side_fall_off_displacement_x: float
    var fall_off_displacement_y: float
    
    if collider_shape is CircleShape2D:
        right_side_fall_off_displacement_x = collider_shape.radius
        fall_off_displacement_y = 0.0
        
    elif collider_shape is CapsuleShape2D:
        if is_rotated_90_degrees:
            right_side_fall_off_displacement_x = \
                    collider_shape.radius + collider_shape.height * 0.5
            fall_off_displacement_y = 0.0
        else:
            right_side_fall_off_displacement_x = collider_shape.radius
            fall_off_displacement_y = -collider_shape.height * 0.5
        
    elif collider_shape is RectangleShape2D:
        if is_rotated_90_degrees:
            right_side_fall_off_displacement_x = collider_shape.extents.y
            fall_off_displacement_y = collider_shape.extents.x
        else:
            right_side_fall_off_displacement_x = collider_shape.extents.x
            fall_off_displacement_y = collider_shape.extents.y
        
    else:
        Utils.error("Invalid Shape2D provided for " + \
                "_calculate_player_center_at_fall_off_point: %s. " + \
                "The supported shapes are: CircleShape2D, CapsuleShape2D, RectangleShape2D." % \
                collider_shape)
    
    right_side_fall_off_displacement_x += EXTRA_FALL_OFF_POSITION_MARGIN
    
    return edge_point + \
            Vector2(-right_side_fall_off_displacement_x if falls_on_left_side else \
                    right_side_fall_off_displacement_x, \
                    fall_off_displacement_y)

static func _prepend_walk_to_fall_off_portion( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        velocity_x_start: float, \
        time_fall_off: float, \
        instructions: MovementInstructions, \
        trajectory: MovementTrajectory, \
        movement_params: MovementParams, \
        falls_on_left_side: bool) -> void:
    var frame_count_before_fall_off := ceil(time_fall_off / Utils.PHYSICS_TIME_STEP)
    
    # Round the fall-off time up, so that we actually consider it to start aligned with the first
    # frame in which it is actually clear of the surface edge.
    time_fall_off = frame_count_before_fall_off * Utils.PHYSICS_TIME_STEP + Geometry.FLOAT_EPSILON
    
    # Increment instruction times.
    
    for instruction in instructions.instructions:
        instruction.time += time_fall_off
    
    instructions.duration += time_fall_off
    
    # Insert the walk-to-fall-off instructions.
    
    var sideways_input_key := \
            "move_left" if \
            falls_on_left_side else \
            "move_right"
    var outward_press := MovementInstruction.new( \
            sideways_input_key, \
            0.0, \
            true)
    var outward_release := MovementInstruction.new( \
            sideways_input_key, \
            time_fall_off - 0.0001, \
            false)
    instructions.instructions.push_front(outward_release)
    instructions.instructions.push_front(outward_press)
    
    # Insert frame state for the walk-to-fall-off portion of the trajectory.
    
    var walking_and_falling_frame_discrete_positions_from_test = PoolVector2Array()
    walking_and_falling_frame_discrete_positions_from_test.resize(frame_count_before_fall_off)
    var walking_and_falling_frame_continuous_positions_from_steps = PoolVector2Array()
    walking_and_falling_frame_continuous_positions_from_steps.resize(frame_count_before_fall_off)
    var walking_and_falling_frame_continuous_velocities_from_steps = PoolVector2Array()
    walking_and_falling_frame_continuous_velocities_from_steps.resize(frame_count_before_fall_off)
    
    walking_and_falling_frame_discrete_positions_from_test.append_array( \
            trajectory.frame_discrete_positions_from_test)
    walking_and_falling_frame_continuous_positions_from_steps.append_array( \
            trajectory.frame_continuous_positions_from_steps)
    walking_and_falling_frame_continuous_velocities_from_steps.append_array( \
            trajectory.frame_continuous_velocities_from_steps)
    
    trajectory.frame_discrete_positions_from_test = \
            walking_and_falling_frame_discrete_positions_from_test
    trajectory.frame_continuous_positions_from_steps = \
            walking_and_falling_frame_continuous_positions_from_steps
    trajectory.frame_continuous_velocities_from_steps = \
            walking_and_falling_frame_continuous_velocities_from_steps
    
    var acceleration_x := -movement_params.walk_acceleration if falls_on_left_side else \
            movement_params.walk_acceleration
    var acceleration := Vector2(acceleration_x, 0.0)
    
    var current_frame_position := start.target_point
    var current_frame_velocity := Vector2(velocity_x_start, \
            PlayerActionHandler.MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION)
    
    for frame_index in range(frame_count_before_fall_off):
        trajectory.frame_discrete_positions_from_test[frame_index] = current_frame_position
        trajectory.frame_continuous_positions_from_steps[frame_index] = current_frame_position
        trajectory.frame_continuous_velocities_from_steps[frame_index] = current_frame_velocity
        
        current_frame_position += current_frame_velocity * Utils.PHYSICS_TIME_STEP
        current_frame_velocity += acceleration * Utils.PHYSICS_TIME_STEP
        clamp(current_frame_velocity.x, \
                -movement_params.max_horizontal_speed_default, \
                movement_params.max_horizontal_speed_default)
