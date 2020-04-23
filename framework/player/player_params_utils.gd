class_name PlayerParamsUtils

static func create_player_params( \
        param_class, \
        global) -> PlayerParams:
    var movement_params: MovementParams = param_class.new()
    
    _calculate_dependent_movement_params(movement_params)
    _check_movement_params(movement_params)
    
    var movement_calculators := _get_movement_calculators(movement_params, global)
    var action_handlers := _get_action_handlers(movement_params, global)

    return PlayerParams.new( \
            movement_params.name, \
            movement_params, \
            movement_calculators, \
            action_handlers)

# Array<PlayerActionHandler>
static func _get_action_handlers( \
        movement_params: MovementParams, \
        global) -> Array:
    var names := movement_params.action_handler_names
    
    var action_handlers := []
    action_handlers.resize(names.size())
    
    var name: String
    for i in range(names.size()):
        name = names[i]
        action_handlers[i] = global.PLAYER_ACTIONS[name]
    
    action_handlers.sort_custom(ActionHandlersComparator, "sort")
    
    return action_handlers

# Array<Movement>
static func _get_movement_calculators( \
        movement_params: MovementParams, \
        global) -> Array:
    var names := movement_params.movement_calculator_names
    
    var movement_calculators := []
    movement_calculators.resize(names.size())
    
    var name: String
    for i in range(names.size()):
        name = names[i]
        movement_calculators[i] = global.EDGE_MOVEMENTS[name]
    
    return movement_calculators

static func _calculate_dependent_movement_params(movement_params: MovementParams) -> void:
    movement_params.gravity_slow_rise = \
            movement_params.gravity_fast_fall * movement_params.slow_rise_gravity_multiplier
    movement_params.collider_half_width_height = Geometry.calculate_half_width_height( \
            movement_params.collider_shape, \
            movement_params.collider_rotation)
    movement_params.min_upward_jump_distance = \
            VerticalMovementUtils.calculate_min_upward_distance(movement_params)
    movement_params.max_upward_jump_distance = \
            VerticalMovementUtils.calculate_max_upward_distance(movement_params)
    movement_params.max_upward_jump_distance = \
            VerticalMovementUtils.calculate_max_upward_distance(movement_params)
    movement_params.time_to_max_upward_jump_distance = \
            MovementUtils.calculate_movement_duration( \
                    -movement_params.max_upward_jump_distance, \
                    movement_params.jump_boost, \
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
            HorizontalMovementUtils.calculate_max_horizontal_displacement_before_returning_to_starting_height( \
                    0.0, \
                    movement_params.jump_boost, \
                    movement_params.max_horizontal_speed_default, \
                    movement_params.gravity_slow_rise, \
                    movement_params.gravity_fast_fall)
    movement_params.wall_jump_max_horizontal_jump_distance = \
            HorizontalMovementUtils.calculate_max_horizontal_displacement_before_returning_to_starting_height( \
                    movement_params.wall_jump_horizontal_boost, \
                    movement_params.jump_boost, \
                    movement_params.max_horizontal_speed_default, \
                    movement_params.gravity_slow_rise, \
                    movement_params.gravity_fast_fall)
    movement_params.stopping_distance_on_default_floor_from_max_speed = \
            MovementUtils.calculate_distance_to_stop_from_friction( \
                    movement_params, \
                    movement_params.max_horizontal_speed_default, \
                    movement_params.gravity_fast_fall, \
                    movement_params.friction_coefficient)
    
    assert(movement_params.action_handler_names.find(MatchExpectedEdgeTrajectoryAction.NAME) < 0)
    if movement_params.syncs_player_velocity_to_edge_trajectory:
        movement_params.action_handler_names.push_back(MatchExpectedEdgeTrajectoryAction.NAME)

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
    assert(movement_params.walk_acceleration >= 0)
    assert(movement_params.climb_up_speed <= 0)
    assert(movement_params.climb_down_speed >= 0)
    assert(movement_params.max_horizontal_speed_default >= 0)
    assert(movement_params.min_horizontal_speed >= 0)
    assert(movement_params.max_vertical_speed >= 0)
    assert(movement_params.max_vertical_speed >= abs(movement_params.jump_boost))
    assert(movement_params.min_vertical_speed >= 0)
    assert(movement_params.fall_through_floor_velocity_boost >= 0)
    assert(movement_params.dash_speed_multiplier >= 0)
    assert(movement_params.dash_duration >= movement_params.dash_fade_duration)
    assert(movement_params.dash_fade_duration >= 0)
    assert(movement_params.dash_cooldown >= 0)
    assert(movement_params.dash_vertical_boost <= 0)
    assert(!movement_params.stops_after_finding_first_valid_edge_for_a_surface_pair or \
            !movement_params.calculates_all_valid_edges_for_a_surface_pair)

class ActionHandlersComparator:
    static func sort( \
            a: PlayerActionHandler, \
            b: PlayerActionHandler) -> bool:
        return a.priority < b.priority
