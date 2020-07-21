extends Node

const LEVEL_RESOURCE_PATHS := [
    "res://levels/level_1.tscn",
    "res://levels/level_2.tscn",
    "res://levels/level_3.tscn",
    "res://levels/level_4.tscn",
    "res://levels/level_5.tscn",
    "res://levels/level_6.tscn",
]

const TEST_RUNNER_SCENE_RESOURCE_PATH := "res://test/test_runner.tscn"

const UTILITY_PANEL_RESOURCE_PATH := \
        "res://framework/controls/panels/utility_panel.tscn"
const WELCOME_PANEL_RESOURCE_PATH := \
        "res://framework/controls/panels/welcome_panel.tscn"

const IN_DEBUG_MODE := true
const IN_TEST_MODE := false
var USES_THREADS := false and OS.can_use_threads()

const UTILITY_PANEL_STARTS_OPEN := false

# Dictionary<AnnotatorType, bool>
const ANNOTATORS_DEFAULT_ENABLEMENT := {
    AnnotatorType.RULER: false,
    AnnotatorType.GRID_INDICES: false,
    AnnotatorType.LEVEL: true,
    AnnotatorType.PLAYER_POSITION: false,
    AnnotatorType.PLAYER_TRAJECTORY: true,
    AnnotatorType.NAVIGATOR: true,
    AnnotatorType.CLICK: true,
    AnnotatorType.SURFACE_SELECTION: true,
}

const STARTING_LEVEL_RESOURCE_PATH := \
        "res://levels/level_6.tscn"
#        "res://test/data/test_level_long_rise.tscn"
#        "res://test/data/test_level_long_fall.tscn"
#        "res://test/data/test_level_far_distance.tscn"
#        "res://levels/level_3.tscn"
#        "res://levels/level_4.tscn"
#        "res://levels/level_5.tscn"

const LOADING_SCREEN_PATH := "res://loading_screen.tscn"

const DEFAULT_PLAYER_NAME := "cat"

var THREAD_COUNT := \
        4 if \
        USES_THREADS else \
        1

const DEBUG_PARAMS := \
        {} if \
        !IN_DEBUG_MODE else \
        {
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
