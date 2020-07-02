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
var USES_THREADS := false and OS.can_use_threads()
const IN_TEST_MODE := false
const UTILITY_PANEL_STARTS_OPEN := true

#const STARTING_LEVEL_RESOURCE_PATH := \
#        "res://test/data/test_level_long_rise.tscn"
#const STARTING_LEVEL_RESOURCE_PATH := \
#        "res://test/data/test_level_long_fall.tscn"
#const STARTING_LEVEL_RESOURCE_PATH := \
#        "res://test/data/test_level_far_distance.tscn"
#const STARTING_LEVEL_RESOURCE_PATH := \
#        "res://levels/level_3.tscn"
#const STARTING_LEVEL_RESOURCE_PATH := \
#        "res://levels/level_4.tscn"
#const STARTING_LEVEL_RESOURCE_PATH := \
#        "res://levels/level_5.tscn"
const STARTING_LEVEL_RESOURCE_PATH := \
        "res://levels/level_6.tscn"

const PLAYER_RESOURCE_PATH := "res://players/cat_player.tscn"
#const PLAYER_RESOURCE_PATH := "res://players/data/test_player.tscn"

var THREAD_COUNT := \
        4 if \
        USES_THREADS else \
        1

const DEBUG_PARAMS := \
        {} if \
        !IN_DEBUG_MODE else \
        {
    is_inspector_enabled = true,
    limit_parsing = {
        player_name = "cat",
#        
        edge = {
            origin = {
                surface_side = SurfaceSide.FLOOR,
            },
            destination = {
                surface_side = SurfaceSide.FLOOR,
            },
        },
#        
#        edge_type = EdgeType.CLIMB_OVER_WALL_TO_FLOOR_EDGE,
#        edge_type = EdgeType.FALL_FROM_WALL_EDGE,
#        edge_type = EdgeType.FALL_FROM_FLOOR_EDGE,
        edge_type = EdgeType.JUMP_INTER_SURFACE_EDGE,
#        edge_type = EdgeType.CLIMB_DOWN_WALL_TO_FLOOR_EDGE,
#        edge_type = EdgeType.WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE,
#        
#        # Level: long rise; fall-from-wall
#        edge = {
#            origin = {
#                surface_side = SurfaceSide.LEFT_WALL,
#                surface_start_vertex = Vector2(0, -448),
#                surface_end_vertex = Vector2(0, -384),
#                position = Vector2(0, -448),
#            },
#            destination = {
#                surface_side = SurfaceSide.FLOOR,
#                surface_start_vertex = Vector2(128, 64),
#                surface_end_vertex = Vector2(192, 64),
#                position = Vector2(128, 64),
#            },
#        },
#        
#        # Level: long rise; jump-up-left
#        edge = {
#            origin = {
#                surface_side = SurfaceSide.FLOOR,
#                surface_start_vertex = Vector2(128, 64),
#                surface_end_vertex = Vector2(192, 64),
#                position = Vector2(128, 64),
#            },
#            destination = {
#                surface_side = SurfaceSide.FLOOR,
#                surface_start_vertex = Vector2(-128, -448),
#                surface_end_vertex = Vector2(0, -448),
#                position = Vector2(-128, -448),
#            },
#        },
#        
#        # Level: long rise; fall-from-floor-lower-right
#        edge = {
#            origin = {
#                surface_side = SurfaceSide.FLOOR,
#                surface_start_vertex = Vector2(128, 64),
#                position = Vector2(192, 64),
#            },
#        },
#        
#        # Level: jump-up-right from long base floor to close short floor
#        edge = {
#            origin = {
#                surface_side = SurfaceSide.FLOOR,
#                surface_start_vertex = Vector2(-960, 256),
#                surface_end_vertex = Vector2(2688, 256),
#            },
#            destination = {
#                surface_side = SurfaceSide.FLOOR,
#                surface_start_vertex = Vector2(128, 64),
#                surface_end_vertex = Vector2(192, 64),
#            },
#        },
    },
    extra_annotations = {},
}
