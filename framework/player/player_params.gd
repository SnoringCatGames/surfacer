extends Reference
class_name PlayerParams

var _movement_params: MovementParams
var _movement_types: Array
var _player_type_configuration: Dictionary

func _init() -> void:
    _movement_params = _create_movement_params()
    _movement_types = _create_movement_types(_movement_params)
    _player_type_configuration = _create_player_type_configuration(_movement_params, _movement_types)

func get_player_type_configuration() -> Dictionary:
    return _player_type_configuration

func _create_player_type_configuration(movement_params: MovementParams, \
        movement_types: Array) -> Dictionary:
    Utils.error("abstract PlayerParams._create_player_type_configuration is not implemented")
    return {}

# Array<PlayerMovement>
func _create_movement_types(movement_params: MovementParams) -> Array:
    Utils.error("abstract PlayerParams._create_movement_types is not implemented")
    return []

func _create_movement_params() -> MovementParams:
    Utils.error("abstract PlayerParams._create_movement_params is not implemented")
    return null
