extends Reference
class_name PlayerParams

var player_resource_path: String
var _movement_params: MovementParams
# Array<EdgeMovementCalculator>
var _movement_calculators: Array
# Array<PlayerActionHandler>
var _action_handlers: Array
var _player_type_configuration: PlayerTypeConfiguration
# TODO: Add type back in.
var global

func _init( \
        name: String, \
        player_resource_path: String, \
        global) -> void:
    self.player_resource_path = player_resource_path
    self.global = global
    
    _movement_params = _create_movement_params()
    _movement_params.gravity_slow_rise = \
            _movement_params.gravity_fast_fall * _movement_params.slow_ascent_gravity_multiplier
    _movement_params.collider_half_width_height = Geometry.calculate_half_width_height( \
            _movement_params.collider_shape, \
            _movement_params.collider_rotation)
    _movement_params.max_upward_jump_distance = \
            VerticalMovementUtils.calculate_max_upward_distance(_movement_params)
    _movement_params.time_to_max_upward_jump_distance = \
            MovementUtils.calculate_movement_duration( \
                    -_movement_params.max_upward_jump_distance, \
                    _movement_params.jump_boost, \
                    _movement_params.gravity_slow_rise)
    # From a basic equation of motion:
    #     v^2 = v_0^2 + 2*a*(s - s_0)
    #     v_0 = 0
    # Algebra:
    #     (s - s_0) = v^2 / 2 / a
    _movement_params.distance_to_max_horizontal_speed = \
            _movement_params.max_horizontal_speed_default * \
            _movement_params.max_horizontal_speed_default / \
            2.0 / _movement_params.walk_acceleration
    _movement_params.distance_to_half_max_horizontal_speed = \
            _movement_params.max_horizontal_speed_default * 0.5 * \
            _movement_params.max_horizontal_speed_default * 0.5 / \
            2.0 / _movement_params.walk_acceleration
    _movement_params.floor_jump_max_horizontal_jump_distance = \
            HorizontalMovementUtils.calculate_max_horizontal_displacement_before_returning_to_starting_height( \
                    0.0, \
                    _movement_params.jump_boost, \
                    _movement_params.max_horizontal_speed_default, \
                    _movement_params.gravity_slow_rise, \
                    _movement_params.gravity_fast_fall)
    _movement_params.wall_jump_max_horizontal_jump_distance = \
            HorizontalMovementUtils.calculate_max_horizontal_displacement_before_returning_to_starting_height( \
                    _movement_params.wall_jump_horizontal_boost, \
                    _movement_params.jump_boost, \
                    _movement_params.max_horizontal_speed_default, \
                    _movement_params.gravity_slow_rise, \
                    _movement_params.gravity_fast_fall)
    _check_movement_params(_movement_params)
    _movement_calculators = _get_movement_calculators()
    
    _action_handlers = _get_action_handlers()
    _action_handlers.sort_custom(self, "_compare_action_handlers")
    
    _player_type_configuration = _create_player_type_configuration( \
            name, \
            _movement_params, \
            _movement_calculators, \
            _action_handlers)

func get_player_type_configuration() -> PlayerTypeConfiguration:
    return _player_type_configuration

func _create_player_type_configuration( \
        name: String, \
        movement_params: MovementParams, \
        movement_calculators: Array, \
        action_handlers: Array) -> PlayerTypeConfiguration:
    var type_configuration = PlayerTypeConfiguration.new()
    type_configuration.name = name
    type_configuration.movement_params = movement_params
    type_configuration.movement_calculators = movement_calculators
    type_configuration.action_handlers = action_handlers
    return type_configuration

# Array<PlayerActionHandler>
func _get_action_handlers() -> Array:
    Utils.error("abstract PlayerParams._get_action_handlers is not implemented")
    return []

# Array<Movement>
func _get_movement_calculators() -> Array:
    Utils.error("abstract PlayerParams._get_movement_calculators is not implemented")
    return []

func _create_movement_params() -> MovementParams:
    Utils.error("abstract PlayerParams._create_movement_params is not implemented")
    return null

func _check_movement_params(movement_params: MovementParams) -> void:
    assert(movement_params.gravity_fast_fall >= 0)
    assert(movement_params.slow_ascent_gravity_multiplier >= 0)
    assert(movement_params.ascent_double_jump_gravity_multiplier >= 0)
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
    assert(movement_params.calculates_edges_from_surface_ends_with_velocity_start_x_zero or \
            movement_params.calculates_edges_with_velocity_start_x_max_speed)

static func _compare_action_handlers( \
        a: PlayerActionHandler, \
        b: PlayerActionHandler) -> bool:
    return a.priority < b.priority
