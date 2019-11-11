extends Node
class_name Global

const LEVEL_RESOURCE_PATHS := [
    "res://levels/level_1.tscn",
    "res://levels/level_2.tscn",
    "res://levels/level_3.tscn",
    "res://levels/level_4.tscn",
    "res://levels/level_5.tscn",
]

const TEST_RUNNER_SCENE_RESOURCE_PATH := "res://framework/test/tests.tscn"

const DEBUG_PANEL_RESOURCE_PATH := "res://framework/menus/debug_panel.tscn"

const IN_DEBUG_MODE := true
const IN_TEST_MODE := false

const STARTING_LEVEL_RESOURCE_PATH := "res://framework/test/test_data/test_level_long_rise.tscn"
#const STARTING_LEVEL_RESOURCE_PATH := "res://levels/level_4.tscn"

const PLAYER_RESOURCE_PATH := "res://players/cat_player.tscn"
#const PLAYER_RESOURCE_PATH := "res://framework/test/test_data/test_player.tscn"

const DEBUG_STATE := {
    in_debug_mode = IN_DEBUG_MODE,
    limit_parsing_to_single_edge = null
#    {
#        player_name = "cat",
#        origin = {
#            surface_side = SurfaceSide.FLOOR,
#            surface_start_vertex = Vector2(128, 64),
#            surface_end_vertex = Vector2(192, 64),
#            near_far_close_position = "near",
#        },
#        destination = {
#            surface_side = SurfaceSide.FLOOR,
#            surface_start_vertex = Vector2(-128, -448),
#            surface_end_vertex = Vector2(0, -448),
#            near_far_close_position = "far",
#        },
#    },
}

const CAMERA_ZOOM := 1.5

const PLAYER_ACTIONS := {}

# Dictionary<String, PlayerTypeConfiguration>
var player_types := {}

var debug_panel: DebugPanel

var current_level

# Keeps track of the current total elapsed time of unpaused gameplay.
var elapsed_play_time_sec: float setget ,_get_elapsed_play_time_sec

# TODO: Verify that all render-frame _process calls in the scene tree happen without interleaving
#       with any _physics_process calls from other nodes in the scene tree.
var _elapsed_latest_play_time_sec: float
var _elapsed_physics_play_time_sec: float
var _elapsed_render_play_time_sec: float

var current_camera: Camera2D setget _set_current_camera, _get_current_camera

var _current_camera: Camera2D

func get_is_paused() -> bool:
    return get_tree().paused

func pause() -> void:
    get_tree().paused = true

func unpause() -> void:
    get_tree().paused = false

func register_player_actions(player_action_classes: Array) -> void:
    # Instantiate the various PlayerActions.
    for player_action_class in player_action_classes:
        PLAYER_ACTIONS[player_action_class.NAME] = player_action_class.new()

func register_player_params(player_param_classes: Array) -> void:
    var params
    var type: PlayerTypeConfiguration
    for param_class in player_param_classes:
        params = param_class.new(self)
        type = params.get_player_type_configuration()
        self.player_types[type.name] = type

func _ready() -> void:
    _elapsed_physics_play_time_sec = 0.0
    _elapsed_render_play_time_sec = 0.0
    _elapsed_latest_play_time_sec = 0.0

func _process(delta: float) -> void:
    _elapsed_render_play_time_sec += delta
    _elapsed_latest_play_time_sec = _elapsed_render_play_time_sec

func _physics_process(delta: float) -> void:
    _elapsed_physics_play_time_sec += delta
    _elapsed_latest_play_time_sec = _elapsed_physics_play_time_sec

func _get_elapsed_play_time_sec() -> float:
    return _elapsed_latest_play_time_sec

func add_overlay_to_current_scene(node: Node) -> void:
    get_tree().get_current_scene().add_child(node)

func _set_current_camera(camera: Camera2D) -> void:
    assert(camera.current)
    _current_camera = camera

func _get_current_camera() -> Camera2D:
    return _current_camera