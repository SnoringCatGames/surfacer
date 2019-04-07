extends Node
class_name Global

# Array<{
#     name: String,
#     type: String,
#     path: String,
# }>
var player_types = {}

var current_level: Level

func register_player_types(player_types: Array) -> void:
    for type in player_types:
        self.player_types[type.name] = type
