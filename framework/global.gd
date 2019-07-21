extends Node
class_name Global

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

const PLAYER_ACTIONS := {}

# Dictionary<String, PlayerTypeConfiguration>
var player_types = {}

var current_level: Level

# Keeps track of the current total elapsed time of unpaused gameplay.
var elapsed_play_time_sec: float setget ,_get_elapsed_play_time_sec

# TODO: Verify that all render-frame _process calls in the scene tree happen without interleaving
#       with any _physics_process calls from other nodes in the scene tree.
var _elapsed_latest_play_time_sec: float
var _elapsed_physics_play_time_sec: float
var _elapsed_render_play_time_sec: float

func get_is_paused() -> bool:
    return get_tree().paused

func pause() -> void:
    get_tree().paused = true

func unpause() -> void:
    get_tree().paused = false

func register_player_params(player_params: Array) -> void:
    var type: PlayerTypeConfiguration
    for params in player_params:
        type = params.get_player_type_configuration()
        self.player_types[type.name] = type

func _init() -> void:
    # Instantiate the various PlayerActions.
    for player_action_class in PLAYER_ACTION_CLASSES:
        PLAYER_ACTIONS[player_action_class.NAME] = player_action_class.new()

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
