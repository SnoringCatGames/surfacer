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
        action_handlers[i] = Su.player_actions[names[i]]
    
    action_handlers.sort_custom(_ActionHandlersComparator, "sort")
    
    return action_handlers


# Array<Movement>
static func _get_edge_calculators(movement_params: MovementParams) -> Array:
    var names := movement_params.edge_calculator_names
    
    var edge_calculators := []
    edge_calculators.resize(names.size())
    
    for i in names.size():
        edge_calculators[i] = Su.edge_movements[names[i]]
    
    return edge_calculators


static func _calculate_dependent_movement_params(
        movement_params: MovementParams) -> void:
    movement_params.gravity_slow_rise = \
            movement_params.gravity_fast_fall * \
            movement_params.slow_rise_gravity_multiplier
    movement_params.collider_half_width_height = \
            Sc.geometry.calculate_half_width_height(
                    movement_params.collider_shape,
                    movement_params.collider_rotation)
    _calculate_fall_from_floor_corner_calc_shape(movement_params)
    movement_params.climb_over_wall_corner_calc_shape = \
            movement_params.collider_shape
    movement_params.climb_over_wall_corner_calc_shape_rotation = \
            movement_params.collider_rotation
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
    
    movement_params.action_handler_names = \
            _get_action_handler_names(movement_params)
    movement_params.edge_calculator_names = \
            _get_edge_calculator_names(movement_params)
    
    assert(movement_params.action_handler_names.find(
            MatchExpectedEdgeTrajectoryAction.NAME) < 0)
    if movement_params.syncs_player_position_to_edge_trajectory or \
            movement_params.syncs_player_velocity_to_edge_trajectory:
        movement_params.action_handler_names.push_back(
                MatchExpectedEdgeTrajectoryAction.NAME)


static func _calculate_fall_from_floor_corner_calc_shape(
        movement_params: MovementParams) -> void:
    var fall_from_floor_shape := RectangleShape2D.new()
    fall_from_floor_shape.extents = movement_params.collider_half_width_height
    movement_params.fall_from_floor_corner_calc_shape = fall_from_floor_shape
    movement_params.fall_from_floor_corner_calc_shape_rotation = 0.0


static func _get_action_handler_names(movement_params: MovementParams) -> Array:
    var names := [
        AirDefaultAction.NAME,
        AllDefaultAction.NAME,
        CapVelocityAction.NAME,
        FloorDefaultAction.NAME,
        FloorWalkAction.NAME,
        FloorFrictionAction.NAME,
    ]
    if movement_params.can_grab_walls:
        names.push_back(WallClimbAction.NAME)
        names.push_back(WallDefaultAction.NAME)
        names.push_back(WallWalkAction.NAME)
        if movement_params.can_jump:
            names.push_back(WallFallAction.NAME)
            names.push_back(WallJumpAction.NAME)
        if movement_params.can_dash:
            names.push_back(WallDashAction.NAME)
    if movement_params.can_grab_ceilings:
        pass
    if movement_params.can_jump:
        names.push_back(FloorFallThroughAction.NAME)
        names.push_back(FloorJumpAction.NAME)
        if movement_params.can_double_jump:
            names.push_back(AirJumpAction.NAME)
    if movement_params.can_dash:
        names.push_back(AirDashAction.NAME)
        names.push_back(FloorDashAction.NAME)
    return names


static func _get_edge_calculator_names(movement_params: MovementParams) -> Array:
    var names := []
    if movement_params.can_grab_walls:
        names.push_back(ClimbDownWallToFloorCalculator.NAME)
        names.push_back(ClimbOverWallToFloorCalculator.NAME)
        names.push_back(WalkToAscendWallFromFloorCalculator.NAME)
        if movement_params.can_jump:
            names.push_back(FallFromWallCalculator.NAME)
    if movement_params.can_jump:
        names.push_back(FallFromFloorCalculator.NAME)
        names.push_back(JumpFromSurfaceCalculator.NAME)
    return names


static func _check_movement_params(movement_params: MovementParams) -> void:
    for layer_name in movement_params.collision_detection_layers:
        assert(layer_name is String)
    for proximity_detection_configs in [
                movement_params.proximity_entered_detection_layers,
                movement_params.proximity_exited_detection_layers,
            ]:
        for proximity_config in proximity_detection_configs:
            assert((
                proximity_config.has("layer_name") and
                proximity_config.layer_name is String and
                proximity_config.has("radius")
            ) or ( \
                proximity_config.has("layer_name") and
                proximity_config.layer_name is String and
                proximity_config.has("shape") and
                proximity_config.shape is Shape2D and
                proximity_config.has("rotation")
            ))
    
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
    assert(!Sc.audio_manifest.are_beats_tracked_by_default or \
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
            movement_params.includes_continuous_trajectory_positions)
    assert(!movement_params.syncs_player_velocity_to_edge_trajectory or \
            movement_params.includes_continuous_trajectory_velocities)
    assert(!movement_params.bypasses_runtime_physics or \
            movement_params.syncs_player_position_to_edge_trajectory)
    
    assert(movement_params.can_grab_walls or (
                !movement_params.edge_calculator_names.has(
                        ClimbOverWallToFloorCalculator.NAME) and \
                !movement_params.edge_calculator_names.has(
                        FallFromWallCalculator.NAME) and \
                !movement_params.edge_calculator_names.has(
                        ClimbDownWallToFloorCalculator.NAME) and \
                !movement_params.edge_calculator_names.has(
                        WalkToAscendWallFromFloorCalculator.NAME) and \
                
                !movement_params.action_handler_names.has(
                        WallClimbAction.NAME) and \
                !movement_params.action_handler_names.has(
                        WallDashAction.NAME) and \
                !movement_params.action_handler_names.has(
                        WallDefaultAction.NAME) and \
                !movement_params.action_handler_names.has(
                        WallFallAction.NAME) and \
                !movement_params.action_handler_names.has(
                        WallJumpAction.NAME) and \
                !movement_params.action_handler_names.has(
                        WallWalkAction.NAME)
            ))
    
    assert(movement_params.can_jump or (
                !movement_params.edge_calculator_names.has(
                        FallFromFloorCalculator.NAME) and \
                !movement_params.edge_calculator_names.has(
                        FallFromWallCalculator.NAME) and \
                !movement_params.edge_calculator_names.has(
                        JumpFromSurfaceCalculator.NAME) and \
                
                !movement_params.action_handler_names.has(
                        AirJumpAction.NAME) and \
                !movement_params.action_handler_names.has(
                        FloorFallThroughAction.NAME) and \
                !movement_params.action_handler_names.has(
                        FloorJumpAction.NAME) and \
                !movement_params.action_handler_names.has(
                        WallFallAction.NAME) and \
                !movement_params.action_handler_names.has(
                        WallJumpAction.NAME)
            ))
    
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
