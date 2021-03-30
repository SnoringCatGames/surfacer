# A collection of utility functions for calculating state related to
# EdgeTrajectory.
class_name EdgeTrajectoryUtils
extends Reference

# Calculates trajectory state for the movement represented by the given
# calculation results.
static func calculate_trajectory_from_calculation_steps( \
        records_profile_or_edge_result_metadata, \
        collision_params: CollisionCalcParams, \
        calc_result: EdgeCalcResult, \
        instructions: EdgeInstructions) -> EdgeTrajectory:
    Gs.profiler.start( \
            SurfacerProfilerMetric.CALCULATE_TRAJECTORY_FROM_CALCULATION_STEPS, \
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
    var frame_continuous_velocities_from_steps := \
            _concatenate_step_frame_velocities(steps)
    
    var distance_from_continuous_frames = \
            _sum_distance_between_frames(frame_continuous_positions_from_steps)
    
    var trajectory := EdgeTrajectory.new( \
            frame_continuous_positions_from_steps, \
            frame_continuous_velocities_from_steps, \
            waypoint_positions, \
            distance_from_continuous_frames)
    
    if collision_params.movement_params.calculates_discrete_frame_state:
        var collision := \
                CollisionCheckUtils.check_instructions_discrete_frame_state( \
                        edge_calc_params, \
                        instructions, \
                        vertical_step, \
                        steps, \
                        trajectory)
        assert(collision == null or \
                (collision.is_valid_collision_state and \
                collision.surface == \
                        edge_calc_params.destination_waypoint.surface))
    
    Gs.profiler.stop_with_optional_metadata( \
            SurfacerProfilerMetric.CALCULATE_TRAJECTORY_FROM_CALCULATION_STEPS, \
            collision_params.thread_id, \
            records_profile_or_edge_result_metadata)
    
    return trajectory

static func _concatenate_step_frame_positions( \
        steps: Array) -> PoolVector2Array:
    var combined_positions := []
    
    for step in steps:
        Gs.utils.concat(combined_positions, step.frame_positions)
        # Since the start-position of the next step is always the same as the
        # end-position of the previous step, we can de-dup them here.
        combined_positions.remove(combined_positions.size() - 1)
    
    # Fix the fencepost problem.
    combined_positions.push_back(steps.back().frame_positions.back())
    
    return PoolVector2Array(combined_positions)

static func _concatenate_step_frame_velocities( \
        steps: Array) -> PoolVector2Array:
    var combined_velocities := []
    
    for step in steps:
        Gs.utils.concat(combined_velocities, step.frame_velocities)
        # Since the start-position of the next step is always the same as the
        # end-position of the previous step, we can de-dup them here.
        combined_velocities.remove(combined_velocities.size() - 1)
    
    # Fix the fencepost problem.
    combined_velocities.push_back(steps.back().frame_velocities.back())
    
    return PoolVector2Array(combined_velocities)

static func _sum_distance_between_frames( \
        frame_positions: PoolVector2Array) -> float:
    if frame_positions.size() < 2:
        return 0.0
    
    var previous_position := frame_positions[0]
    var next_position: Vector2
    var sum := 0.0
    for i in range(1, frame_positions.size()):
        next_position = frame_positions[i]
        sum += previous_position.distance_to(next_position)
        previous_position = next_position
    return sum

static func sub_trajectory( \
        base_trajectory: EdgeTrajectory, \
        start_time: float) -> EdgeTrajectory:
    assert(base_trajectory.frame_continuous_positions_from_steps.size() == \
            base_trajectory.frame_continuous_velocities_from_steps.size())
    var start_index := ceil(start_time / Time.PHYSICS_TIME_STEP_SEC)
    var frame_continuous_positions_from_steps := \
            Gs.utils.sub_pool_vector2_array( \
                    base_trajectory.frame_continuous_positions_from_steps, \
                    start_index)
    var frame_continuous_velocities_from_steps := \
            Gs.utils.sub_pool_vector2_array( \
                    base_trajectory.frame_continuous_velocities_from_steps, \
                    start_index)
    # TODO: Try to use frame_continuous_positions_from_steps to detect which
    #       waypoint positions we've passed.
    var waypoint_positions := base_trajectory.waypoint_positions
    var distance_from_continuous_frames := \
            _sum_distance_between_frames(frame_continuous_positions_from_steps)
    return EdgeTrajectory.new( \
            frame_continuous_positions_from_steps, \
            frame_continuous_velocities_from_steps, \
            waypoint_positions, \
            distance_from_continuous_frames)
