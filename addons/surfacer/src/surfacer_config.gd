extends Node

var uses_threads := false and OS.can_use_threads()

var utility_panel_starts_open := false

var default_player_name := "cat"

var group_name_human_players := "human_players"
var group_name_computer_players := "computer_players"
var group_name_surfaces := "surfaces"
var group_name_squirrel_destinations := "squirrel_destinations"

var thread_count := \
        4 if \
        uses_threads else \
        1

var is_logging_events := false

var debug_params := {
    is_inspector_enabled = true,
#    limit_parsing = {
#        player_name = "cat",
#        
#        edge_type = EdgeType.CLIMB_OVER_WALL_TO_FLOOR_EDGE,
#        edge_type = EdgeType.FALL_FROM_WALL_EDGE,
#        edge_type = EdgeType.FALL_FROM_FLOOR_EDGE,
#        edge_type = EdgeType.JUMP_INTER_SURFACE_EDGE,
#        edge_type = EdgeType.CLIMB_DOWN_WALL_TO_FLOOR_EDGE,
#        edge_type = EdgeType.WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE,
#        
#        edge = {
#            origin = {
#                surface_side = SurfaceSide.RIGHT_WALL,
#                surface_start_vertex = Vector2(64, 768),
#                #position = Vector2(64, 704),
#                epsilon = 10,
#            },
#            destination = {
#                surface_side = SurfaceSide.LEFT_WALL,
#                surface_start_vertex = Vector2(-384, 704),
#                #position = Vector2(-384, 737),
#                epsilon = 10,
#            },
#            #velocity_start = Vector2(0, -1000),
#        },
#    },
    extra_annotations = {},
}

var player_actions := {}

var edge_movements := {}

# Dictionary<String, PlayerParams>
var player_params := {}

var current_player_for_clicks: Player
var platform_graph_inspector: PlatformGraphInspector
var legend: Legend
var selection_description: SelectionDescription
var utility_panel: UtilityPanel
var welcome_panel: WelcomePanel
var annotators: Annotators

var is_level_ready := false

# ---

var player_action_classes := [
    preload("res://addons/surfacer/src/player/action/action_handlers/air_dash_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/air_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/air_jump_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/all_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/cap_velocity_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_dash_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_fall_through_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_friction_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_jump_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_walk_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/match_expected_edge_trajectory_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_climb_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_dash_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_fall_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_jump_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/wall_walk_action.gd"),
]

var edge_movement_classes := [
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/air_to_surface_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/climb_down_wall_to_floor_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/climb_over_wall_to_floor_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/fall_from_floor_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/fall_from_wall_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/jump_inter_surface_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/jump_from_surface_to_air_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/walk_to_ascend_wall_from_floor_calculator.gd"),
]

var player_param_classes := [
    preload("res://src/players/cat/cat_params.gd"),
    preload("res://src/players/squirrel/squirrel_params.gd"),
#    preload("res://test/data/test_player_params.gd"),
]

func _init() -> void:
    ScaffoldUtils.print("SurfacerConfig._init")
