class_name PlayerParamsUtils


static func create_player_params(param_class) -> PlayerParams:
    var movement_params: MovementParams = param_class.new()
    
    _calculate_dependent_movement_params(movement_params)
    _check_movement_params(movement_params)
    
    var edge_calculators := _get_edge_calculators(movement_params)
    var action_handlers := _get_action_handlers(movement_params)

    return PlayerParams.new(
            movement_params.name,
            movement_params,
            edge_calculators,
            action_handlers)


# Array<PlayerActionHandler>
static func _get_action_handlers(movement_params: MovementParams) -> Array:
    var names := movement_params.action_handler_names
    
    var action_handlers := []
    action_handlers.resize(names.size())
    
    for i in names.size():
        action_handlers[i] = Surfacer.player_actions[names[i]]
    
    action_handlers.sort_custom(_ActionHandlersComparator, "sort")
    
    return action_handlers


# Array<Movement>
static func _get_edge_calculators(movement_params: MovementParams) -> Array:
    var names := movement_params.edge_calculator_names
    
    var edge_calculators := []
    edge_calculators.resize(names.size())
    
    for i in names.size():
        edge_calculators[i] = Surfacer.edge_movements[names[i]]
    
    return edge_calculators


static func _calculate_dependent_movement_params(
        movement_params: MovementParams) -> void:
    movement_params.gravity_slow_rise = \
            movement_params.gravity_fast_fall * \
            movement_params.slow_rise_gravity_multiplier
    movement_params.collider_half_width_height = \
            Gs.geometry.calculate_half_width_height(
                    movement_params.collider_shape,
                    movement_params.collider_rotation)
    movement_params.min_upward_jump_distance = VerticalMovementUtils \
            .calculate_min_upward_distance(movement_params)
    movement_params.max_upward_jump_distance = VerticalMovementUtils \
            .calculate_max_upward_distance(movement_params)
    movement_params.max_upward_jump_distance = VerticalMovementUtils \
            .calculate_max_upward_distance(movement_params)
    movement_params.time_to_max_upward_jump_distance = MovementUtils \
            .calculate_movement_duration(
                    -movement_params.max_upward_jump_distance,
                    movement_params.jump_boost,
                    movement_params.gravity_slow_rise)
    # From a basic equation of motion:
    #     v^2 = v_0^2 + 2*a*(s - s_0)
    #     v_0 = 0
    # Algebra:
    #     (s - s_0) = v^2 / 2 / a
    movement_params.distance_to_max_horizontal_speed = \
            movement_params.max_horizontal_speed_default * \
            movement_params.max_horizontal_speed_default / \
            2.0 / movement_params.walk_acceleration
    movement_params.distance_to_half_max_horizontal_speed = \
            movement_params.max_horizontal_speed_default * 0.5 * \
            movement_params.max_horizontal_speed_default * 0.5 / \
            2.0 / movement_params.walk_acceleration
    movement_params.floor_jump_max_horizontal_jump_distance = \
            HorizontalMovementUtils \
                    .calculate_max_horizontal_displacement_before_returning_to_starting_height(
                            0.0,
                            movement_params.jump_boost,
                            movement_params.max_horizontal_speed_default,
                            movement_params.gravity_slow_rise,
                            movement_params.gravity_fast_fall)
    movement_params.wall_jump_max_horizontal_jump_distance = \
            HorizontalMovementUtils \
                    .calculate_max_horizontal_displacement_before_returning_to_starting_height(
                            movement_params.wall_jump_horizontal_boost,
                            movement_params.jump_boost,
                            movement_params.max_horizontal_speed_default,
                            movement_params.gravity_slow_rise,
                            movement_params.gravity_fast_fall)
    movement_params.stopping_distance_on_default_floor_from_max_speed = \
            MovementUtils.calculate_distance_to_stop_from_friction(
                    movement_params,
                    movement_params.max_horizontal_speed_default,
                    movement_params.gravity_fast_fall,
                    movement_params.friction_coefficient)
    
    assert(movement_params.action_handler_names.find(
            MatchExpectedEdgeTrajectoryAction.NAME) < 0)
    if movement_params.syncs_player_position_to_edge_trajectory or \
            movement_params.syncs_player_velocity_to_edge_trajectory:
        movement_params.action_handler_names.push_back(
                MatchExpectedEdgeTrajectoryAction.NAME)


static func _check_movement_params(movement_params: MovementParams) -> void:
    assert(movement_params.gravity_fast_fall >= 0)
    assert(movement_params.slow_rise_gravity_multiplier >= 0)
    assert(movement_params.rise_double_jump_gravity_multiplier >= 0)
    assert(movement_params.jump_boost <= 0)
    assert(movement_params.in_air_horizontal_acceleration >= 0)
    assert(movement_params.max_jump_chain >= 0)
    assert(movement_params.wall_jump_horizontal_boost >= 0 and \
            movement_params.wall_jump_horizontal_boost <= \
            movement_params.max_horizontal_speed_default)
    assert(movement_params.wall_fall_horizontal_boost >= 0 and \
            movement_params.wall_fall_horizontal_boost <= \
            movement_params.max_horizontal_speed_default)
    assert(movement_params.walk_acceleration >= 0)
    assert(movement_params.climb_up_speed <= 0)
    assert(movement_params.climb_down_speed >= 0)
    assert(movement_params.max_horizontal_speed_default >= 0)
    assert(movement_params.min_horizontal_speed >= 0)
    assert(movement_params.max_vertical_speed >= 0)
    assert(movement_params.max_vertical_speed >= \
            abs(movement_params.jump_boost))
    assert(movement_params.min_vertical_speed >= 0)
    assert(movement_params.fall_through_floor_velocity_boost >= 0)
    assert(movement_params.dash_speed_multiplier >= 0)
    assert(movement_params.dash_duration >= movement_params.dash_fade_duration)
    assert(movement_params.dash_fade_duration >= 0)
    assert(movement_params.dash_cooldown >= 0)
    assert(movement_params.dash_vertical_boost <= 0)
    # If we're tracking beats, then we need the preselection trajectories to
    # match the resulting navigation trajectories.
    assert(!Gs.are_beats_tracked_by_default or \
            movement_params.also_optimizes_preselection_path or \
            !movement_params.optimizes_edge_jump_positions_at_run_time and \
            !movement_params.optimizes_edge_land_positions_at_run_time)
    assert(!movement_params \
            .stops_after_finding_first_valid_edge_for_a_surface_pair or \
            !movement_params.calculates_all_valid_edges_for_a_surface_pair)
    assert(!movement_params.forces_player_position_to_match_path_at_end or \
            !movement_params \
                    .prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets)
    assert(!movement_params.syncs_player_position_to_edge_trajectory or \
            movement_params.includes_continuous_frame_positions)
    assert(!movement_params.syncs_player_velocity_to_edge_trajectory or \
            movement_params.includes_continuous_frame_velocities)
    assert(!movement_params.bypasses_runtime_physics or \
            movement_params.syncs_player_position_to_edge_trajectory)
    
    _check_animator_params(movement_params.animator_params)


static func _check_animator_params(
        animator_params: PlayerAnimatorParams) -> void:
    assert(animator_params.rest_name != "")
    assert(animator_params.rest_on_wall_name != "")
    assert(animator_params.jump_rise_name != "")
    assert(animator_params.jump_fall_name != "")
    assert(animator_params.walk_name != "")
    assert(animator_params.climb_up_name != "")
    assert(animator_params.climb_down_name != "")
    
    assert(animator_params.rest_playback_rate != 0.0 and 
            !is_inf(animator_params.rest_playback_rate))
    assert(animator_params.rest_on_wall_playback_rate != 0.0 and 
            !is_inf(animator_params.rest_on_wall_playback_rate))
    assert(animator_params.jump_rise_playback_rate != 0.0 and 
            !is_inf(animator_params.jump_rise_playback_rate))
    assert(animator_params.jump_fall_playback_rate != 0.0 and 
            !is_inf(animator_params.jump_fall_playback_rate))
    assert(animator_params.walk_playback_rate != 0.0 and 
            !is_inf(animator_params.walk_playback_rate))
    assert(animator_params.climb_up_playback_rate != 0.0 and 
            !is_inf(animator_params.climb_up_playback_rate))
    assert(animator_params.climb_down_playback_rate != 0.0 and \
            !is_inf(animator_params.climb_down_playback_rate))


class _ActionHandlersComparator:
    static func sort(
            a: PlayerActionHandler,
            b: PlayerActionHandler) -> bool:
        return a.priority < b.priority
