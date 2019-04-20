extends Node

const CatParams = preload("res://players/cat_params.gd")
const SquirrelParams = preload("res://players/squirrel_params.gd")

var player_params := [
    CatParams.new(),
    SquirrelParams.new(),
]

func _enter_tree() -> void:
    var global := $"/root/Global"
    global.register_player_params(player_params)
