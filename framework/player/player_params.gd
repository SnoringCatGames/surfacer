extends Reference
class_name PlayerParams

var player_resource_path: String
var _movement_params: MovementParams
# Array<PlayerMovement>
var _movement_types: Array
# Array<PlayerActionHandler>
var _action_handlers: Array
var _player_type_configuration: PlayerTypeConfiguration
# TODO: Add type back in.
var global

func _init(name: String, player_resource_path: String, global) -> void:
    self.player_resource_path = player_resource_path
    self.global = global
    
    _movement_params = _create_movement_params()
    _movement_params.gravity_slow_ascent = \
            _movement_params.gravity_fast_fall * _movement_params.slow_ascent_gravity_multiplier
    _movement_params.collider_half_width_height = Geometry.calculate_half_width_height( \
            _movement_params.collider_shape, _movement_params.collider_rotation)
    _movement_params.max_upward_jump_distance = \
            PlayerMovement.calculate_max_upward_movement(_movement_params)
    _movement_params.max_horizontal_jump_distance = \
            PlayerMovement.calculate_max_horizontal_movement( \
                    _movement_params, _movement_params.jump_boost)
    _check_movement_params(_movement_params)
    _movement_types = _create_movement_types(_movement_params)
    
    _action_handlers = _create_action_handlers()
    _action_handlers.sort_custom(self, "_compare_action_handlers")
    
    _player_type_configuration = _create_player_type_configuration( \
            name, _movement_params, _movement_types, _action_handlers)

func get_player_type_configuration() -> PlayerTypeConfiguration:
    return _player_type_configuration

func _create_player_type_configuration(name: String, movement_params: MovementParams, \
        movement_types: Array, action_handlers: Array) -> PlayerTypeConfiguration:
    var type_configuration = PlayerTypeConfiguration.new()
    type_configuration.name = name
    type_configuration.movement_params = movement_params
    type_configuration.movement_types = movement_types
    type_configuration.action_handlers = action_handlers
    return type_configuration

# Array<PlayerActionHandler>
func _create_action_handlers() -> Array:
    Utils.error("abstract PlayerParams._create_action_handlers is not implemented")
    return []

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

static func _compare_action_handlers(a: PlayerActionHandler, b: PlayerActionHandler) -> bool:
    return a.priority < b.priority
