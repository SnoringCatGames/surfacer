class_name EdgeTrajectoryUtils
extends Reference
# A collection of utility functions for calculating state related to
# EdgeTrajectory.


# Calculates trajectory state for the movement represented by the given
# calculation results.
static func calculate_trajectory_from_calculation_steps(
        records_profile_or_edge_result_metadata,
        collision_params: CollisionCalcParams,
        calc_result: EdgeCalcResult,
        instructions: EdgeInstructions) -> EdgeTrajectory:
    Sc.profiler.start(
            "calculate_trajectory_from_calculation_steps",
            collision_params.thread_id)
    
    var edge_calc_params := calc_result.edge_calc_params
    var steps := calc_result.horizontal_steps
    var vertical_step := calc_result.vertical_step
    
    # Record the trajectory waypoint positions.
    var waypoint_positions := []
    for step in steps:
        waypoint_positions.push_back(step.position_step_end)
    
    var frame_continuous_positions_from_steps := \
            _concatenate_step_frame_positions(steps)
    var distance_from_continuous_trajectory := \
            sum_distance_between_frames(frame_continuous_positions_from_steps)
    if !collision_params.movement_params \
            .includes_continuous_trajectory_positions:
        frame_continuous_positions_from_steps = PoolVector2Array()
    
    var frame_continuous_velocities_from_steps := \
            _concatenate_step_frame_velocities(steps) if \
            collision_params.movement_params \
                    .includes_continuous_trajectory_velocities else \
            PoolVector2Array()
    
    var trajectory := EdgeTrajectory.new(
            frame_continuous_positions_from_steps,
            frame_continuous_velocities_from_steps,
            waypoint_positions,
            distance_from_continuous_trajectory)
    
    if collision_params.movement_params.includes_discrete_trajectory_state:
        var collision := CollisionCheckUtils \
                .check_instructions_discrete_trajectory_state(
                        edge_calc_params,
                        instructions,
                        vertical_step,
                        steps,
                        trajectory)
        assert(collision == null or \
                (collision.is_valid_collision_state and \
                collision.surface == \
                        edge_calc_params.destination_waypoint.surface))
    
    Sc.profiler.stop_with_optional_metadata(
            "calculate_trajectory_from_calculation_steps",
            collision_params.thread_id,
            records_profile_or_edge_result_metadata)
    
    return trajectory


static func _concatenate_step_frame_positions(
        steps: Array) -> PoolVector2Array:
    var combined_positions := []
    
    for step in steps:
        Sc.utils.concat(combined_positions, step.frame_positions)
        # Since the start-position of the next step is always the same as the
        # end-position of the previous step, we can de-dup them here.
        combined_positions.remove(combined_positions.size() - 1)
    
    # Fix the fencepost problem.
    combined_positions.push_back(steps.back().frame_positions.back())
    
    return PoolVector2Array(combined_positions)


static func _concatenate_step_frame_velocities(
        steps: Array) -> PoolVector2Array:
    var combined_velocities := []
    
    for step in steps:
        Sc.utils.concat(combined_velocities, step.frame_velocities)
        # Since the start-position of the next step is always the same as the
        # end-position of the previous step, we can de-dup them here.
        combined_velocities.remove(combined_velocities.size() - 1)
    
    # Fix the fencepost problem.
    combined_velocities.push_back(steps.back().frame_velocities.back())
    
    return PoolVector2Array(combined_velocities)


static func sum_distance_between_frames(frame_positions) -> float:
    if frame_positions.size() < 2:
        return 0.0
    
    var previous_position: Vector2 = frame_positions[0]
    var sum := 0.0
    for i in range(1, frame_positions.size()):
        var next_position: Vector2 = frame_positions[i]
        sum += previous_position.distance_to(next_position)
        previous_position = next_position
    return sum


static func sub_trajectory(
        base_trajectory: EdgeTrajectory,
        start_time: float) -> EdgeTrajectory:
    var includes_continuous_positions := \
            !base_trajectory.frame_continuous_positions_from_steps.empty()
    var includes_continuous_velocities := \
            !base_trajectory.frame_continuous_velocities_from_steps.empty()
    
    assert(!includes_continuous_positions or \
            !includes_continuous_velocities or \
            base_trajectory.frame_continuous_positions_from_steps.size() == \
            base_trajectory.frame_continuous_velocities_from_steps.size())
    
    var start_index := int(start_time / ScaffolderTime.PHYSICS_TIME_STEP)
    
    var frame_continuous_positions_from_steps: PoolVector2Array = \
                Sc.utils.sub_pool_vector2_array(
                        base_trajectory.frame_continuous_positions_from_steps,
                        start_index) if \
                includes_continuous_positions else \
                PoolVector2Array()
    var frame_continuous_velocities_from_steps: PoolVector2Array = \
            Sc.utils.sub_pool_vector2_array(
                    base_trajectory.frame_continuous_velocities_from_steps,
                    start_index) if \
                includes_continuous_velocities else \
                PoolVector2Array()
    
    # TODO: Try to use frame_continuous_positions_from_steps to detect which
    #       waypoint positions we've passed.
    var waypoint_positions := base_trajectory.waypoint_positions
    
    # TODO: Calculate a more accurate value for this distance when we aren't
    #       saving continuous frame state.
    var distance_from_continuous_trajectory := \
            sum_distance_between_frames(
                    frame_continuous_positions_from_steps) if \
            includes_continuous_positions else \
            base_trajectory.distance_from_continuous_trajectory
    
    return EdgeTrajectory.new(
            frame_continuous_positions_from_steps,
            frame_continuous_velocities_from_steps,
            waypoint_positions,
            distance_from_continuous_trajectory)

static func create_trajectory_placeholder_hack(edge: Edge) -> EdgeTrajectory:
    var position_start := edge.start_position_along_surface.target_point
    var position_end := edge.end_position_along_surface.target_point
    var velocity_start := edge.velocity_start
    var velocity_end := edge.velocity_end
    var frame_count := \
            int(ceil(edge.duration / ScaffolderTime.PHYSICS_TIME_STEP))
    
    var positions := PoolVector2Array()
    if edge.movement_params.includes_continuous_trajectory_positions:
        positions.resize(frame_count)
        for i in frame_count:
            positions[i] = position_start
        positions[frame_count - 1] = position_end
        if frame_count > 2:
            positions[frame_count - 2] = position_end
    
    var velocities := PoolVector2Array()
    if edge.movement_params.includes_continuous_trajectory_velocities:
        velocities.resize(frame_count)
        for i in frame_count:
            velocities[i] = velocity_start
        velocities[frame_count - 1] = velocity_end
        if frame_count > 2:
            velocities[frame_count - 2] = velocity_end
    
    var waypoint_positions := [position_end]
    
    var distance := edge.distance
    
    var trajectory := EdgeTrajectory.new(
            positions,
            velocities,
            waypoint_positions,
            distance)
    
    return trajectory
