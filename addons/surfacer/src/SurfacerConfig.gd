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
    preload("res://addons/surfacer/src/player/action/action_handlers/AirDashAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/AirDefaultAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/AirJumpAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/AllDefaultAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/CapVelocityAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/FloorDashAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/FloorDefaultAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/FallThroughFloorAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/FloorFrictionAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/FloorJumpAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/FloorWalkAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/MatchExpectedEdgeTrajectoryAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/WallClimbAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/WallDashAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/WallDefaultAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/WallFallAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/WallJumpAction.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/WallWalkAction.gd"),
]

var edge_movement_classes := [
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/AirToSurfaceCalculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/ClimbDownWallToFloorCalculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/ClimbOverWallToFloorCalculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/FallFromFloorCalculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/FallFromWallCalculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/JumpInterSurfaceCalculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/JumpFromSurfaceToAirCalculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/WalkToAscendWallFromFloorCalculator.gd"),
]

var player_param_classes := [
    preload("res://src/players/cat/CatParams.gd"),
    preload("res://src/players/squirrel/SquirrelParams.gd"),
#    preload("res://test/data/TestPlayerParams.gd"),
]

func _init() -> void:
    Gs.utils.print("SurfacerConfig._init")
