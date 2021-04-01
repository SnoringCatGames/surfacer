class_name SurfacerConfig
extends Node

var is_inspector_enabled: bool
var is_logging: bool
var utility_panel_starts_open: bool
var uses_threads_for_platform_graph_calculation: bool

var debug_params := {
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

var default_player_name := "cat"

var group_name_human_players := "human_players"
var group_name_computer_players := "computer_players"
var group_name_surfaces := "surfaces"
var group_name_squirrel_destinations := "squirrel_destinations"

var non_surface_parser_metric_keys := [
    "find_surfaces_in_jump_fall_range_from_surface",
    "edge_calc_broad_phase_check",
    "calculate_jump_land_positions_for_surface_pair",
    "narrow_phase_edge_calculation",
    "check_continuous_horizontal_step_for_collision",
    
    "calculate_jump_inter_surface_edge",
    "fall_from_floor_walk_to_fall_off_point_calculation",
    "find_surfaces_in_fall_range_from_point",
    "find_landing_trajectory_between_positions",
    "calculate_land_positions_on_surface",
    "create_edge_calc_params",
    "calculate_vertical_step",
    "calculate_jump_inter_surface_steps",
    "convert_calculation_steps_to_movement_instructions",
    "calculate_trajectory_from_calculation_steps",
    "calculate_horizontal_step",
    "calculate_waypoints_around_surface",
    
    # Counts
    "invalid_collision_state_in_calculate_steps_between_waypoints",
    "collision_in_calculate_steps_between_waypoints",
    "calculate_steps_between_waypoints_without_backtracking_on_height",
    "calculate_steps_between_waypoints_with_backtracking_on_height",
    
    "navigator_navigate_to_position",
    "navigator_find_path",
    "navigator_optimize_edges_for_approach",
    "navigator_start_edge",
]

var surface_parser_metric_keys := [
    "parse_tile_map_into_sides_duration",
    "remove_internal_surfaces_duration",
    "merge_continuous_surfaces_duration",
    "remove_internal_collinear_vertices_duration",
    "store_surfaces_duration",
    "assign_neighbor_surfaces_duration",
    "calculate_shape_bounding_boxes_for_surfaces_duration",
    "assert_surfaces_fully_calculated_duration",
]

var player_actions := {}

var edge_movements := {}

# Dictionary<String, PlayerParams>
var player_params := {}

var current_player_for_clicks: Player
var platform_graph_inspector: PlatformGraphInspector
var legend: Legend
var selection_description: SelectionDescription
var utility_panel: UtilityPanel
var annotators: Annotators

var ann_defaults := AnnotationElementDefaults.new()

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

func register_app_manifest(manifest: Dictionary) -> void:
    self.is_inspector_enabled = manifest.is_inspector_enabled
    self.is_logging = manifest.is_surfacer_logging
    self.utility_panel_starts_open = manifest.utility_panel_starts_open
    self.uses_threads_for_platform_graph_calculation = \
            uses_threads_for_platform_graph_calculation
    Gs.profiler.preregister_metric_keys(non_surface_parser_metric_keys)
    Gs.profiler.preregister_metric_keys(surface_parser_metric_keys)
