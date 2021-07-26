class_name SurfacerMovementManifest
extends Node


# ---

const DEFAULT_ACTION_HANDLER_CLASSES := [
    preload("res://addons/surfacer/src/player/action/action_handlers/air_dash_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/air_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/air_jump_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/all_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/cap_velocity_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_dash_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/floor_default_action.gd"),
    preload("res://addons/surfacer/src/player/action/action_handlers/fall_through_floor_action.gd"),
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

const DEFAULT_EDGE_CALCULATOR_CLASSES := [
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/from_air_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/climb_down_wall_to_floor_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/climb_over_wall_to_floor_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/fall_from_floor_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/fall_from_wall_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/jump_from_surface_calculator.gd"),
    preload("res://addons/surfacer/src/platform_graph/edge/calculators/walk_to_ascend_wall_from_floor_calculator.gd"),
]

# ---

var gravity_default := 5000.0
var gravity_slow_rise_multiplier_default := 0.38
var gravity_double_jump_slow_rise_multiplier_default := 0.68

var walk_acceleration_default := 8000.0
var in_air_horizontal_acceleration_default := 2500.0
var climb_up_speed_default := -230.0
var climb_down_speed_default := 120.0

var friction_coefficient_default := 1.25

var jump_boost_default := -900.0
var wall_jump_horizontal_boost_default := 200.0
var wall_fall_horizontal_boost_default := 20.0

var max_horizontal_speed_default_default := 320.0
var max_vertical_speed_default := 2800.0
var min_horizontal_speed := 5.0
var min_vertical_speed := 0.0

var dash_speed_multiplier_default := 3.0
var dash_vertical_boost_default := -300.0
var dash_duration_default := 0.3
var dash_fade_duration_default := 0.1
var dash_cooldown_default := 1.0

var additional_edge_weight_offset_default := 128.0
var walking_edge_weight_multiplier_default := 1.2
var climbing_edge_weight_multiplier_default := 1.8
var air_edge_weight_multiplier_default := 1.0

# Dictionary<String, MovementParams>
var player_movement_params := {}

# Dictionary<String, PlayerActionHandler>
var action_handlers := {}

# Dictionary<String, EdgeCalculator>
var edge_calculators := {}

var _action_handler_classes: Array
var _edge_calculator_classes: Array

# ---


# FIXME: ------------------

func _register_manifest(manifest: Dictionary) -> void:
    self._action_handler_classes = surfacer_manifest.action_handler_classes
    self._edge_calculator_classes = surfacer_manifest.edge_calculator_classes
    
    if surfacer_manifest.has("gravity_default"):
        self.gravity_default = \
                surfacer_manifest.gravity_default
    if surfacer_manifest.has("gravity_slow_rise_multiplier_default"):
        self.gravity_slow_rise_multiplier_default = \
                surfacer_manifest.gravity_slow_rise_multiplier_default
    if surfacer_manifest.has("gravity_double_jump_slow_rise_multiplier_default"):
        self.gravity_double_jump_slow_rise_multiplier_default = \
                surfacer_manifest.gravity_double_jump_slow_rise_multiplier_default
    if surfacer_manifest.has("walk_acceleration_default"):
        self.walk_acceleration_default = \
                surfacer_manifest.walk_acceleration_default
    if surfacer_manifest.has("in_air_horizontal_acceleration_default"):
        self.in_air_horizontal_acceleration_default = \
                surfacer_manifest.in_air_horizontal_acceleration_default
    if surfacer_manifest.has("climb_up_speed_default"):
        self.climb_up_speed_default = \
                surfacer_manifest.climb_up_speed_default
    if surfacer_manifest.has("climb_down_speed_default"):
        self.climb_down_speed_default = \
                surfacer_manifest.climb_down_speed_default
    if surfacer_manifest.has("friction_coefficient_default"):
        self.friction_coefficient_default = \
                surfacer_manifest.friction_coefficient_default
    if surfacer_manifest.has("jump_boost_default"):
        self.jump_boost_default = \
                surfacer_manifest.jump_boost_default
    if surfacer_manifest.has("wall_jump_horizontal_boost_default"):
        self.wall_jump_horizontal_boost_default = \
                surfacer_manifest.wall_jump_horizontal_boost_default
    if surfacer_manifest.has("wall_fall_horizontal_boost_default"):
        self.wall_fall_horizontal_boost_default = \
                surfacer_manifest.wall_fall_horizontal_boost_default
    
    if surfacer_manifest.has("max_horizontal_speed_default_default"):
        self.max_horizontal_speed_default_default = \
                surfacer_manifest.max_horizontal_speed_default_default
    if surfacer_manifest.has("max_vertical_speed_default"):
        self.max_vertical_speed_default = \
                surfacer_manifest.max_vertical_speed_default
    if surfacer_manifest.has("min_horizontal_speed"):
        self.min_horizontal_speed = \
                surfacer_manifest.min_horizontal_speed
    if surfacer_manifest.has("min_vertical_speed"):
        self.min_vertical_speed = \
                surfacer_manifest.min_vertical_speed
    
    if surfacer_manifest.has("dash_speed_multiplier_default"):
        self.dash_speed_multiplier_default = \
                surfacer_manifest.dash_speed_multiplier_default
    if surfacer_manifest.has("dash_vertical_boost_default"):
        self.dash_vertical_boost_default = \
                surfacer_manifest.dash_vertical_boost_default
    if surfacer_manifest.has("dash_duration_default"):
        self.dash_duration_default = \
                surfacer_manifest.dash_duration_default
    if surfacer_manifest.has("dash_fade_duration_default"):
        self.dash_fade_duration_default = \
                surfacer_manifest.dash_fade_duration_default
    if surfacer_manifest.has("dash_cooldown_default"):
        self.dash_cooldown_default = \
                surfacer_manifest.dash_cooldown_default
    
    if surfacer_manifest.has("additional_edge_weight_offset_default"):
        self.additional_edge_weight_offset_default = \
                surfacer_manifest.additional_edge_weight_offset_default
    if surfacer_manifest.has("walking_edge_weight_multiplier_default"):
        self.walking_edge_weight_multiplier_default = \
                surfacer_manifest.walking_edge_weight_multiplier_default
    if surfacer_manifest.has("climbing_edge_weight_multiplier_default"):
        self.climbing_edge_weight_multiplier_default = \
                surfacer_manifest.climbing_edge_weight_multiplier_default
    if surfacer_manifest.has("air_edge_weight_multiplier_default"):
        self.air_edge_weight_multiplier_default = \
                surfacer_manifest.air_edge_weight_multiplier_default


func _validate_configuration() -> void:
    assert(Su.gravity_default >= 0)
    assert(Su.gravity_slow_rise_multiplier_default >= 0)
    assert(Su.gravity_double_jump_slow_rise_multiplier_default >= 0)
    
    assert(Su.walk_acceleration_default >= 0)
    assert(Su.in_air_horizontal_acceleration_default >= 0)
    assert(Su.climb_up_speed_default <= 0)
    assert(Su.climb_down_speed_default >= 0)
    
    assert(Su.jump_boost_default <= 0)
    assert(Su.wall_jump_horizontal_boost_default >= 0 and \
            Su.wall_jump_horizontal_boost_default <= \
            Su.max_horizontal_speed_default_default)
    assert(Su.wall_fall_horizontal_boost_default >= 0 and \
            Su.wall_fall_horizontal_boost_default <= \
            Su.max_horizontal_speed_default_default)
    
    assert(Su.max_horizontal_speed_default_default >= 0)
    assert(Su.max_vertical_speed_default >= 0)
    assert(Su.min_horizontal_speed >= 0)
    assert(Su.max_vertical_speed_default >= abs(Su.jump_boost_default))
    assert(Su.min_vertical_speed >= 0)
    
    assert(Su.dash_speed_multiplier_default >= 0)
    assert(Su.dash_vertical_boost_default <= 0)
    assert(Su.dash_duration_default >= Su.dash_fade_duration_default)
    assert(Su.dash_fade_duration_default >= 0)
    assert(Su.dash_cooldown_default >= 0)
