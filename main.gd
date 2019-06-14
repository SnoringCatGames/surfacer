extends Node

const CatParams = preload("res://players/cat_params.gd")
const SquirrelParams = preload("res://players/squirrel_params.gd")
const TestPlayerParams = preload("res://framework/test/test_data/test_player_params.gd")

const IN_TEST_MODE := false

var player_params := [
    CatParams.new(),
    SquirrelParams.new(),
    TestPlayerParams.new(),
]

func _enter_tree() -> void:
    var global := $"/root/Global"
    global.register_player_params(player_params)
    
    if IN_TEST_MODE:
        _run_tests()

func _run_tests() -> void:
    # First, remove the normal Level.
    var all_levels: Array = Utils.get_children_by_type(self, Level)
    assert(all_levels.size() == 1)
    var level: Level = all_levels[0]
    remove_child(level)
    
    # Then, add the Gut test runner.
    var tests_scene = load("res://framework/test/tests.tscn")
    var tests = tests_scene.instance()
    add_child(tests)
