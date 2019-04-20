extends Node
class_name Global

# Dictionary<
# String,
# {
#     name: String,
#     type: String,
#     movement_params: MovementParams,
#     movement_types: Array<PlayerMovement>,
# }>
var player_types = {}

var current_level: Level

func register_player_params(player_params: Array) -> void:
    var type: Dictionary
    for params in player_params:
        type = params.get_player_type_configuration()
        self.player_types[type.name] = type
