extends Node

const PLAYER_TYPES := [
    {
        name = "cat",
        type = "human",
        path = "res://players/cat_player.gd",
    },
    {
        name = "squirrel",
        type = "computer",
        path = "res://players/squirrel_player.gd",
    },
]

func _enter_tree() -> void:
    var global := get_node("/root/Global")
    global.register_player_types(PLAYER_TYPES)
