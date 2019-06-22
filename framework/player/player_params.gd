extends Reference
class_name PlayerParams

var _movement_params: MovementParams
var _movement_types: Array
var _player_type_configuration: PlayerTypeConfiguration

func _init() -> void:
    _movement_params = _create_movement_params()
    _calculate_collider_half_width_height()
    _calculate_max_upward_and_horizontal_movement()
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

func _calculate_collider_half_width_height() -> void:
    _movement_params.collider_half_width_height = Geometry.calculate_half_width_height( \
            _movement_params.collider_shape, _movement_params.collider_rotation)

func _calculate_max_upward_and_horizontal_movement() -> void:
    # FIXME: F: Add support for double jumps, dash, etc.

    _movement_params.max_upward_distance = \
            -(_movement_params.jump_boost * _movement_params.jump_boost) / 2 / \
            (_movement_params.gravity * _movement_params.ascent_gravity_multiplier)
    
    # Take into account the slow gravity of ascent and the fast gravity of descent.
    # FIXME: B: Re-calculate this; add a multiplier (x2) to allow for additional distance when the
    #        destination is below.
    _movement_params.max_horizontal_distance = (-_movement_params.jump_boost / \
            _movement_params.gravity * _movement_params.max_horizontal_speed_default) / \
            (1 + _movement_params.ascent_gravity_multiplier)
