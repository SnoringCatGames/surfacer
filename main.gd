extends Node
class_name Main

const LOADING_SCREEN_PATH := "res://loading_screen.tscn"

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
    preload("res://framework/platform_graph/edge/edge_calculators/air_to_surface_calculator.gd"),
    preload("res://framework/platform_graph/edge/edge_calculators/climb_down_wall_to_floor_calculator.gd"),
    preload("res://framework/platform_graph/edge/edge_calculators/climb_over_wall_to_floor_calculator.gd"),
    preload("res://framework/platform_graph/edge/edge_calculators/fall_from_floor_calculator.gd"),
    preload("res://framework/platform_graph/edge/edge_calculators/fall_from_wall_calculator.gd"),
    preload("res://framework/platform_graph/edge/edge_calculators/jump_inter_surface_calculator.gd"),
    preload("res://framework/platform_graph/edge/edge_calculators/jump_from_surface_to_air_calculator.gd"),
    preload("res://framework/platform_graph/edge/edge_calculators/walk_to_ascend_wall_from_floor_calculator.gd"),
]

const PLAYER_PARAM_CLASSES := [
    preload("res://players/cat_params.gd"),
    preload("res://players/squirrel_params.gd"),
    preload("res://test/data/test_player_params.gd"),
]

var global: Global
var loading_screen: Node
var camera_controller: CameraController
var overlays: Overlays
var level: Level

func _enter_tree() -> void:
    global = $"/root/Global"
    
    global.register_player_actions(PLAYER_ACTION_CLASSES)
    global.register_edge_movements(EDGE_MOVEMENT_CLASSES)
    global.register_player_params(PLAYER_PARAM_CLASSES)
    
    if Global.IN_TEST_MODE:
        var scene_path := Global.TEST_RUNNER_SCENE_RESOURCE_PATH
        var test_scene = Utils.add_scene( \
                self, \
                scene_path)
    else:
        camera_controller = CameraController.new()
        add_child(camera_controller)
        overlays = Overlays.new()
        add_child(overlays)
        loading_screen = Utils.add_scene( \
                overlays.screen_layer, \
                LOADING_SCREEN_PATH)

func _process(delta: float) -> void:
    # FIXME: Figure out a better way of loading/parsing the level without blocking the main thread?
    
    if !Global.IN_TEST_MODE and \
            level == null and \
            global._get_elapsed_play_time_sec() > 0.5:
        # Start loading the level and calculating the platform graphs.
        var scene_path := Global.STARTING_LEVEL_RESOURCE_PATH
        level = Utils.add_scene( \
                self, \
                scene_path, \
                false)
        
    if loading_screen != null and \
            global._get_elapsed_play_time_sec() > 2.0:
        # Hide the loading screen and show the level.
        level.visible = true
        overlays.screen_layer.remove_child(loading_screen)
        loading_screen.queue_free()
        loading_screen = null
        
        # Add the player after removing the loading screen, since the camera will track the player,
        # which makes the loading screen look offset.
        var position := \
                Vector2(160.0, 0.0) if \
                Global.STARTING_LEVEL_RESOURCE_PATH.find("test_") >= 0 else \
                Vector2.ZERO
        level.add_player( \
                Global.PLAYER_RESOURCE_PATH, \
                false, \
                position)
