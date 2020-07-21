extends Node

const PLAYER_ACTION_CLASSES := [
    preload("res://framework/player/action/action_handlers/air_dash_action.gd"),
    preload("res://framework/player/action/action_handlers/air_default_action.gd"),
    preload("res://framework/player/action/action_handlers/air_jump_action.gd"),
    preload("res://framework/player/action/action_handlers/all_default_action.gd"),
    preload("res://framework/player/action/action_handlers/cap_velocity_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_dash_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_default_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_fall_through_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_friction_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_jump_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_walk_action.gd"),
    preload("res://framework/player/action/action_handlers/match_expected_edge_trajectory_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_climb_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_dash_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_default_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_fall_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_jump_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_walk_action.gd"),
]

const EDGE_MOVEMENT_CLASSES := [
    preload("res://framework/platform_graph/edge/calculators/air_to_surface_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/climb_down_wall_to_floor_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/climb_over_wall_to_floor_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/fall_from_floor_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/fall_from_wall_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/jump_inter_surface_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/jump_from_surface_to_air_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/walk_to_ascend_wall_from_floor_calculator.gd"),
]

const PLAYER_PARAM_CLASSES := [
    preload("res://players/cat/cat_params.gd"),
    preload("res://players/squirrel/squirrel_params.gd"),
#    preload("res://test/data/test_player_params.gd"),
]

func _init() -> void:
    Global.register_player_actions(PLAYER_ACTION_CLASSES)
    Global.register_edge_movements(EDGE_MOVEMENT_CLASSES)
    Global.register_player_params(PLAYER_PARAM_CLASSES)
