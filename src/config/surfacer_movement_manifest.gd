tool
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


func _init() -> void:
    Sc.logger.on_global_init(self, "SurfacerMovementManifest")


func _register_manifest(manifest: Dictionary) -> void:
    self._action_handler_classes = manifest.action_handler_classes
    self._edge_calculator_classes = manifest.edge_calculator_classes
    
    if manifest.has("gravity_default"):
        self.gravity_default = \
                manifest.gravity_default
    if manifest.has("gravity_slow_rise_multiplier_default"):
        self.gravity_slow_rise_multiplier_default = \
                manifest.gravity_slow_rise_multiplier_default
    if manifest.has("gravity_double_jump_slow_rise_multiplier_default"):
        self.gravity_double_jump_slow_rise_multiplier_default = \
                manifest.gravity_double_jump_slow_rise_multiplier_default
    if manifest.has("walk_acceleration_default"):
        self.walk_acceleration_default = \
                manifest.walk_acceleration_default
    if manifest.has("in_air_horizontal_acceleration_default"):
        self.in_air_horizontal_acceleration_default = \
                manifest.in_air_horizontal_acceleration_default
    if manifest.has("climb_up_speed_default"):
        self.climb_up_speed_default = \
                manifest.climb_up_speed_default
    if manifest.has("climb_down_speed_default"):
        self.climb_down_speed_default = \
                manifest.climb_down_speed_default
    if manifest.has("friction_coefficient_default"):
        self.friction_coefficient_default = \
                manifest.friction_coefficient_default
    if manifest.has("jump_boost_default"):
        self.jump_boost_default = \
                manifest.jump_boost_default
    if manifest.has("wall_jump_horizontal_boost_default"):
        self.wall_jump_horizontal_boost_default = \
                manifest.wall_jump_horizontal_boost_default
    if manifest.has("wall_fall_horizontal_boost_default"):
        self.wall_fall_horizontal_boost_default = \
                manifest.wall_fall_horizontal_boost_default
    
    if manifest.has("max_horizontal_speed_default_default"):
        self.max_horizontal_speed_default_default = \
                manifest.max_horizontal_speed_default_default
    if manifest.has("max_vertical_speed_default"):
        self.max_vertical_speed_default = \
                manifest.max_vertical_speed_default
    if manifest.has("min_horizontal_speed"):
        self.min_horizontal_speed = \
                manifest.min_horizontal_speed
    if manifest.has("min_vertical_speed"):
        self.min_vertical_speed = \
                manifest.min_vertical_speed
    
    if manifest.has("dash_speed_multiplier_default"):
        self.dash_speed_multiplier_default = \
                manifest.dash_speed_multiplier_default
    if manifest.has("dash_vertical_boost_default"):
        self.dash_vertical_boost_default = \
                manifest.dash_vertical_boost_default
    if manifest.has("dash_duration_default"):
        self.dash_duration_default = \
                manifest.dash_duration_default
    if manifest.has("dash_fade_duration_default"):
        self.dash_fade_duration_default = \
                manifest.dash_fade_duration_default
    if manifest.has("dash_cooldown_default"):
        self.dash_cooldown_default = \
                manifest.dash_cooldown_default
    
    if manifest.has("additional_edge_weight_offset_default"):
        self.additional_edge_weight_offset_default = \
                manifest.additional_edge_weight_offset_default
    if manifest.has("walking_edge_weight_multiplier_default"):
        self.walking_edge_weight_multiplier_default = \
                manifest.walking_edge_weight_multiplier_default
    if manifest.has("climbing_edge_weight_multiplier_default"):
        self.climbing_edge_weight_multiplier_default = \
                manifest.climbing_edge_weight_multiplier_default
    if manifest.has("air_edge_weight_multiplier_default"):
        self.air_edge_weight_multiplier_default = \
                manifest.air_edge_weight_multiplier_default


func _validate_configuration() -> void:
    assert(Su.movement.gravity_default >= 0)
    assert(Su.movement.gravity_slow_rise_multiplier_default >= 0)
    assert(Su.movement.gravity_double_jump_slow_rise_multiplier_default >= 0)
    
    assert(Su.movement.walk_acceleration_default >= 0)
    assert(Su.movement.in_air_horizontal_acceleration_default >= 0)
    assert(Su.movement.climb_up_speed_default <= 0)
    assert(Su.movement.climb_down_speed_default >= 0)
    
    assert(Su.movement.jump_boost_default <= 0)
    assert(Su.movement.wall_jump_horizontal_boost_default >= 0 and \
            Su.movement.wall_jump_horizontal_boost_default <= \
            Su.movement.max_horizontal_speed_default_default)
    assert(Su.movement.wall_fall_horizontal_boost_default >= 0 and \
            Su.movement.wall_fall_horizontal_boost_default <= \
            Su.movement.max_horizontal_speed_default_default)
    
    assert(Su.movement.max_horizontal_speed_default_default >= 0)
    assert(Su.movement.max_vertical_speed_default >= 0)
    assert(Su.movement.min_horizontal_speed >= 0)
    assert(Su.movement.max_vertical_speed_default >= abs(Su.movement.jump_boost_default))
    assert(Su.movement.min_vertical_speed >= 0)
    
    assert(Su.movement.dash_speed_multiplier_default >= 0)
    assert(Su.movement.dash_vertical_boost_default <= 0)
    assert(Su.movement.dash_duration_default >= Su.movement.dash_fade_duration_default)
    assert(Su.movement.dash_fade_duration_default >= 0)
    assert(Su.movement.dash_cooldown_default >= 0)


func get_default_action_handler_names(
        movement_params: MovementParams) -> Array:
    var names := [
        "AirDefaultAction",
        "AllDefaultAction",
        "CapVelocityAction",
        "FloorDefaultAction",
        "FloorWalkAction",
        "FloorFrictionAction",
    ]
    if movement_params.can_grab_walls:
        names.push_back("WallClimbAction")
        names.push_back("WallDefaultAction")
        names.push_back("WallWalkAction")
        if movement_params.can_jump:
            names.push_back("WallFallAction")
            names.push_back("WallJumpAction")
        if movement_params.can_dash:
            names.push_back("WallDashAction")
    if movement_params.can_grab_ceilings:
        pass
    if movement_params.can_jump:
        names.push_back("FloorFallThroughAction")
        names.push_back("FloorJumpAction")
        if movement_params.can_double_jump:
            names.push_back("AirJumpAction")
    if movement_params.can_dash:
        names.push_back("AirDashAction")
        names.push_back("FloorDashAction")
    return names


func get_default_edge_calculator_names(
        movement_params: MovementParams) -> Array:
    var edge_calculators := []
    if movement_params.can_grab_walls:
        edge_calculators.push_back("ClimbDownWallToFloorCalculator")
        edge_calculators.push_back("ClimbOverWallToFloorCalculator")
        edge_calculators.push_back("WalkToAscendWallFromFloorCalculator")
        if movement_params.can_jump:
            edge_calculators.push_back("FallFromWallCalculator")
    if movement_params.can_jump:
        edge_calculators.push_back("FallFromFloorCalculator")
        edge_calculators.push_back("JumpFromSurfaceCalculator")
    return edge_calculators


func get_action_handlers_from_names(
        names: Array,
        includes_edge_match: bool) -> Array:
    var action_handlers := []
    for name in names:
        action_handlers.push_back(Su.movement.action_handlers[name])
    
    var name := "MatchExpectedEdgeTrajectoryAction"
    if includes_edge_match and !names.has(name):
        action_handlers.push_back(Su.movement.action_handlers[name])
    elif !includes_edge_match and names.has(name):
        names.erase(Su.movement.action_handlers[name])
    
    action_handlers.sort_custom(_PlayerActionHandlerComparator, "sort")
    return action_handlers


func get_edge_calculators_from_names(names: Array) -> Array:
    var edge_calculators := []
    for name in names:
        edge_calculators.push_back(Su.movement.edge_calculators[name])
    return edge_calculators


# These calculations reference other scripts, which in-turn reference
# MovementParams, so we keep this logic here instead of in MovementParams,
# where they would cause circular dependencies.
func _calculate_dependent_movement_params(
        movement_params: MovementParams) -> void:
    movement_params.min_upward_jump_distance = VerticalMovementUtils \
            .calculate_min_upward_distance(movement_params)
    movement_params.max_upward_jump_distance = VerticalMovementUtils \
            .calculate_max_upward_distance(movement_params)
    movement_params.max_upward_jump_distance = VerticalMovementUtils \
            .calculate_max_upward_distance(movement_params)
    movement_params.time_to_max_upward_jump_distance = \
            MovementUtils.calculate_movement_duration(
                    -movement_params.max_upward_jump_distance,
                    movement_params.jump_boost,
                    movement_params.gravity_slow_rise)
    # From a basic equation of motion:
    #     v^2 = v_0^2 + 2*a*(s - s_0)
    #     v_0 = 0
    # Algebra:
    #     (s - s_0) = v^2 / 2 / a
    movement_params.distance_to_max_horizontal_speed = \
            movement_params.max_horizontal_speed_default * \
            movement_params.max_horizontal_speed_default / \
            2.0 / movement_params.walk_acceleration
    movement_params.distance_to_half_max_horizontal_speed = \
            movement_params.max_horizontal_speed_default * 0.5 * \
            movement_params.max_horizontal_speed_default * 0.5 / \
            2.0 / movement_params.walk_acceleration
    movement_params.floor_jump_max_horizontal_jump_distance = \
            HorizontalMovementUtils \
                    .calculate_max_horizontal_displacement_before_returning_to_starting_height(
                            0.0,
                            movement_params.jump_boost,
                            movement_params.max_horizontal_speed_default,
                            movement_params.gravity_slow_rise,
                            movement_params.gravity_fast_fall)
    movement_params.wall_jump_max_horizontal_jump_distance = \
            HorizontalMovementUtils \
                    .calculate_max_horizontal_displacement_before_returning_to_starting_height(
                            movement_params.wall_jump_horizontal_boost,
                            movement_params.jump_boost,
                            movement_params.max_horizontal_speed_default,
                            movement_params.gravity_slow_rise,
                            movement_params.gravity_fast_fall)
    movement_params.stopping_distance_on_default_floor_from_max_speed = \
            MovementUtils.calculate_distance_to_stop_from_friction(
                    movement_params,
                    movement_params.max_horizontal_speed_default,
                    movement_params.gravity_fast_fall,
                    movement_params.friction_coefficient)


class _PlayerActionHandlerComparator:
    static func sort(
            a: PlayerActionHandler,
            b: PlayerActionHandler) -> bool:
        return a.priority < b.priority