extends Node

const IN_DEBUG_MODE := true
const IN_TEST_MODE := false
var USES_THREADS := false and OS.can_use_threads()

const UTILITY_PANEL_STARTS_OPEN := false

const DEFAULT_PLAYER_NAME := "cat"

const GROUP_NAME_HUMAN_PLAYERS := "human_players"
const GROUP_NAME_COMPUTER_PLAYERS := "computer_players"
const GROUP_NAME_SURFACES := "surfaces"
const GROUP_NAME_SQUIRREL_DESTINATIONS := "squirrel_destinations"

var THREAD_COUNT := \
        4 if \
        USES_THREADS else \
        1

var is_logging_events := false

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
