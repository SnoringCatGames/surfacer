extends Reference
class_name PlayerParams

var _movement_params: MovementParams
var _movement_types: Array
var _player_type_configuration: PlayerTypeConfiguration

func _init() -> void:
    _movement_params = _create_movement_params()
    _movement_params.gravity_slow_ascent = \
            _movement_params.gravity_fast_fall * _movement_params.slow_ascent_gravity_multiplier
    _movement_params.collider_half_width_height = Geometry.calculate_half_width_height( \
            _movement_params.collider_shape, _movement_params.collider_rotation)
    _movement_params.max_upward_distance = _calculate_max_upward_movement(_movement_params)
    _movement_params.max_horizontal_distance = _calculate_max_horizontal_movement(_movement_params)
    _check_movement_params(_movement_params)
    _movement_types = _create_movement_types(_movement_params)
    _player_type_configuration = \
            _create_player_type_configuration(_movement_params, _movement_types)

func get_player_type_configuration() -> PlayerTypeConfiguration:
    return _player_type_configuration

func _create_player_type_configuration(movement_params: MovementParams, \
        movement_types: Array) -> PlayerTypeConfiguration:
    Utils.error("abstract PlayerParams._create_player_type_configuration is not implemented")
    return null

# Array<PlayerMovement>
func _create_movement_types(movement_params: MovementParams) -> Array:
    Utils.error("abstract PlayerParams._create_movement_types is not implemented")
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
    assert(movement_params.wall_jump_horizontal_multiplier >= 0)
    assert(movement_params.walk_acceleration >= 0)
    assert(movement_params.climb_up_speed <= 0)
    assert(movement_params.climb_down_speed >= 0)
    assert(movement_params.max_horizontal_speed_default >= 0)
    assert(movement_params.min_horizontal_speed >= 0)
    assert(movement_params.max_vertical_speed >= 0)
    assert(movement_params.max_vertical_speed >= abs(movement_params.jump_boost))
    assert(movement_params.min_vertical_speed >= 0)
    assert(movement_params.fall_through_floor_velocity_boost >= 0)
    assert(movement_params.min_speed_to_maintain_vertical_collision >= 0)
    assert(movement_params.min_speed_to_maintain_horizontal_collision >= 0)
    assert(movement_params.dash_speed_multiplier >= 0)
    assert(movement_params.dash_duration >= 0)
    assert(movement_params.dash_fade_duration >= 0)
    assert(movement_params.dash_cooldown >= 0)
    assert(movement_params.dash_vertical_boost <= 0)

static func _calculate_max_upward_movement(movement_params: MovementParams) -> float:
    # From a basic equation of motion:
    # - v^2 = v_0^2 + 2*a*(s - s_0)
    # - s_0 = 0
    # - v = 0
    # - Algebra...
    # - s = -v_0^2 / 2 / a
    # FIXME: F: Add support for double jumps, dash, etc.
    return -(movement_params.jump_boost * movement_params.jump_boost) / 2 / \
            movement_params.gravity_slow_ascent

static func _calculate_max_horizontal_movement(movement_params: MovementParams) -> float:
    # Take into account the slow gravity of ascent and the fast gravity of descent.
    # FIXME: F: Add support for double jumps, dash, etc.
    # FIXME: B: Add a multiplier (x2?) to allow for additional distance when the destination is
    #           below.
    # FIXME: A: Add horizontal acceleration

    # v = v_0 + a*t
    var max_time_to_peak := -movement_params.jump_boost / movement_params.gravity_slow_ascent
    # s = s_0 + v_0*t + 0.5*a*t*t
    var max_peak_height := movement_params.jump_boost * max_time_to_peak + \
            0.5 * movement_params.gravity_slow_ascent * max_time_to_peak * max_time_to_peak
    # v^2 = v_0^2 + 2*a*(s - s_0)
    var max_velocity_when_returning_to_starting_height := \
            sqrt(2 * movement_params.gravity_fast_fall * -max_peak_height)
    # v = v_0 + a*t
    var max_time_for_descent_from_peak_to_starting_height := \
            max_velocity_when_returning_to_starting_height / movement_params.gravity_fast_fall
    var max_time_to_starting_height := \
            max_time_to_peak + max_time_for_descent_from_peak_to_starting_height
    var max_horizontal_distance_to_starting_height := \
            max_time_to_starting_height * movement_params.max_horizontal_speed_default
    
    var MULTIPLIER_TO_ALLOW_FOR_DESTINATIONS_THAT_ARE_BELOW := 2.0
    
    return max_horizontal_distance_to_starting_height * \
            MULTIPLIER_TO_ALLOW_FOR_DESTINATIONS_THAT_ARE_BELOW
