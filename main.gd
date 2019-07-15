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
const IN_HUMAN_PLAYER_MODE := false

const STARTING_LEVEL_RESOURCE_PATH := "res://framework/test/test_data/test_level_long_rise.tscn"
#const STARTING_LEVEL_RESOURCE_PATH := "res://levels/level_4.tscn"

var level: Level

func _enter_tree() -> void:
    var global := $"/root/Global"
    global.register_player_params(PLAYER_PARAMS)
    
    var scene_path := TEST_RUNNER_SCENE_RESOURCE_PATH if IN_TEST_MODE else \
            STARTING_LEVEL_RESOURCE_PATH
    level = Utils.add_scene(self, scene_path)

func _ready() -> void:
    var player_resource_path := TestPlayerParams.PLAYER_RESOURCE_PATH if IN_HUMAN_PLAYER_MODE else \
            TestPlayerParams.PLAYER_RESOURCE_PATH
    var position := Vector2(160.0, 0.0) if STARTING_LEVEL_RESOURCE_PATH.find("test_") >= 0 \
            else Vector2.ZERO
    level.add_player(player_resource_path, IN_HUMAN_PLAYER_MODE, position)