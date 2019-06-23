extends Reference
class_name PlayerParams

var _movement_params: MovementParams
var _movement_types: Array
var _player_type_configuration: PlayerTypeConfiguration

func _init() -> void:
    _movement_params = _create_movement_params()
    _movement_params.collider_half_width_height = Geometry.calculate_half_width_height( \
            _movement_params.collider_shape, _movement_params.collider_rotation)
    _movement_params.max_upward_distance = _calculate_max_horizontal_movement(_movement_params)
    _movement_params.max_horizontal_distance = _calculate_max_upward_movement(_movement_params)
    _check_movement_params(movement_params)
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
    assert(gravity >= 0)
    assert(ascent_gravity_multiplier >= 0)
    assert(ascent_double_jump_gravity_multiplier >= 0)
    assert(jump_boost <= 0)
    assert(in_air_horizontal_acceleration >= 0)
    assert(max_jump_chain >= 0)
    assert(wall_jump_horizontal_multiplier >= 0)
    assert(walk_acceleration >= 0)
    assert(climb_up_speed <= 0)
    assert(climb_down_speed >= 0)
    assert(max_horizontal_speed_default >= 0)
    assert(min_horizontal_speed >= 0)
    assert(max_vertical_speed >= 0)
    assert(max_vertical_speed >= abs(jump_boost))
    assert(min_vertical_speed >= 0)
    assert(fall_through_floor_velocity_boost >= 0)
    assert(min_speed_to_maintain_vertical_collision >= 0)
    assert(min_speed_to_maintain_horizontal_collision >= 0)
    assert(dash_speed_multiplier >= 0)
    assert(dash_duration >= 0)
    assert(dash_fade_duration >= 0)
    assert(dash_cooldown >= 0)
    assert(dash_vertical_boost >= 0)

static func _calculate_max_horizontal_movement(movement_params: MovementParams) -> float:
    # FIXME: F: Add support for double jumps, dash, etc.
    # FIXME: B: Re-calculate this; add a multiplier (x2) to allow for additional distance when the
    #        destination is below.
    return -(movement_params.jump_boost * movement_params.jump_boost) / 2 / \
            (movement_params.gravity * movement_params.ascent_gravity_multiplier)

static func _calculate_max_upward_movement(movement_params: MovementParams) -> float:
    # Take into account the slow gravity of ascent and the fast gravity of descent.
    # FIXME: F: Add support for double jumps, dash, etc.
    return (-movement_params.jump_boost / \
            movement_params.gravity * movement_params.max_horizontal_speed_default) / \
            (1 + movement_params.ascent_gravity_multiplier)
