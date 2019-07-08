extends Node
class_name Main

const CatParams = preload("res://players/cat_params.gd")
const SquirrelParams = preload("res://players/squirrel_params.gd")
const TestPlayerParams = preload("res://framework/test/test_data/test_player_params.gd")

var PLAYER_PARAMS := [
    CatParams.new(),
    SquirrelParams.new(),
    TestPlayerParams.new(),
]

const LEVEL_RESOURCE_PATHS := [
    "res://levels/level_1.tscn",
    "res://levels/level_2.tscn",
    "res://levels/level_3.tscn",
    "res://levels/level_4.tscn",
    "res://levels/level_5.tscn",
]

const TEST_RUNNER_SCENE_RESOURCE_PATH := "res://framework/test/tests.tscn"

const IN_TEST_MODE := false

const STARTING_LEVEL_RESOURCE_PATH := "res://framework/test/test_data/test_level_long_rise.tscn"
#const STARTING_LEVEL_RESOURCE_PATH := "res://levels/level_4.tscn"

func _enter_tree() -> void:
    var global := $"/root/Global"
    global.register_player_params(PLAYER_PARAMS)
    
    if IN_TEST_MODE:
        _add_scene(TEST_RUNNER_SCENE_RESOURCE_PATH)
    else:
        _add_scene(STARTING_LEVEL_RESOURCE_PATH)

func _add_scene(resource_path: String) -> void:
    var tests_scene := load(resource_path)
    var tests_node = tests_scene.instance()
    add_child(tests_node)
