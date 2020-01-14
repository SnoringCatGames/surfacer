extends Node
class_name Main

const PLAYER_ACTION_CLASSES := [
    preload("res://framework/player/action/action_handlers/air_dash_action.gd"),
    preload("res://framework/player/action/action_handlers/air_default_action.gd"),
    preload("res://framework/player/action/action_handlers/air_jump_action.gd"),
    preload("res://framework/player/action/action_handlers/all_default_action.gd"),
    preload("res://framework/player/action/action_handlers/cap_velocity_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_dash_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_default_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_fall_through_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_jump_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_walk_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_climb_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_dash_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_default_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_fall_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_jump_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_walk_action.gd"),
]

const EDGE_MOVEMENT_CLASSES := [
    preload("res://framework/edge_movement/models/movement_calculators/climb_down_wall_to_floor_movement.gd"),
    preload("res://framework/edge_movement/models/movement_calculators/climb_over_wall_to_floor_movement.gd"),
    preload("res://framework/edge_movement/models/movement_calculators/climb_up_wall_from_floor_movement.gd"),
    preload("res://framework/edge_movement/models/movement_calculators/fall_from_floor_movement.gd"),
    preload("res://framework/edge_movement/models/movement_calculators/fall_from_wall_movement.gd"),
    preload("res://framework/edge_movement/models/movement_calculators/jump_from_platform_movement.gd"),
]

const PLAYER_PARAM_CLASSES := [
    preload("res://players/cat_params.gd"),
    preload("res://players/squirrel_params.gd"),
    preload("res://framework/test/test_data/test_player_params.gd"),
]

var level: Level

func _enter_tree() -> void:
    var global := $"/root/Global"
    
    global.register_player_actions(PLAYER_ACTION_CLASSES)
    global.register_edge_movements(EDGE_MOVEMENT_CLASSES)
    global.register_player_params(PLAYER_PARAM_CLASSES)
    
    var scene_path := Global.TEST_RUNNER_SCENE_RESOURCE_PATH if Global.IN_TEST_MODE else \
            Global.STARTING_LEVEL_RESOURCE_PATH
    level = Utils.add_scene(self, scene_path)

func _ready() -> void:
    var position := Vector2(160.0, 0.0) if Global.STARTING_LEVEL_RESOURCE_PATH.find("test_") >= 0 \
            else Vector2.ZERO
    level.add_player(Global.PLAYER_RESOURCE_PATH, false, position)
