tool
class_name MovementParams, \
"res://addons/surfacer/assets/images/editor_icons/movement_params.png"
extends Node2D


# FIXME: -----------------------
#var name: String

# FIXME: -----------------------
# String|PackedScene
#var player_path_or_scene

# FIXME: -----------------------
#var animator_params: PlayerAnimatorParams

# FIXME: -----------------------
## Array<String>
#var edge_calculator_names: Array
## Array<String>
#var action_handler_names: Array

# --- Important parameters ---

export var can_grab_walls := false setget _set_can_grab_walls
export var can_grab_ceilings := false setget _set_can_grab_ceilings
var can_grab_floors := true
export var can_jump := true setget _set_can_jump
export var can_dash := false setget _set_can_dash
export var can_double_jump := false setget _set_can_double_jump

# --- Multipliers for parameters whose global defaults are configured in Su ---

export var gravity_multiplier := 1.0 \
        setget _set_gravity_multiplier
export var gravity_slow_rise_multiplier_multiplier := 1.0  \
        setget _set_gravity_slow_rise_multiplier_multiplier
export var gravity_double_jump_slow_rise_multiplier_multiplier := 1.0 \
        setget _set_gravity_double_jump_slow_rise_multiplier_multiplier

export var walk_acceleration_multiplier := 1.0 \
        setget _set_walk_acceleration_multiplier
export var in_air_horizontal_acceleration_multiplier := 1.0 \
        setget _set_in_air_horizontal_acceleration_multiplier
export var climb_up_speed_multiplier := 1.0 \
        setget _set_climb_up_speed_multiplier
export var climb_down_speed_multiplier := 1.0 \
        setget _set_climb_down_speed_multiplier

export var friction_coefficient_multiplier := 1.0 \
        setget _set_friction_coefficient_multiplier

export var jump_boost_multiplier := 1.0 \
        setget _set_jump_boost_multiplier
export var wall_jump_horizontal_boost_multiplier := 1.0 \
        setget _set_wall_jump_horizontal_boost_multiplier
export var wall_fall_horizontal_boost_multiplier := 1.0 \
        setget _set_wall_fall_horizontal_boost_multiplier

export var max_horizontal_speed_default_multiplier := 1.0 \
        setget _set_max_horizontal_speed_default_multiplier
export var max_vertical_speed_multiplier := 1.0 \
        setget _set_max_vertical_speed_multiplier

export var dash_speed_multiplier_multiplier := 1.0 \
        setget _set_dash_speed_multiplier_multiplier
export var dash_vertical_boost_multiplier := 1.0 \
        setget _set_dash_vertical_boost_multiplier
export var dash_duration_multiplier := 1.0 \
        setget _set_dash_duration_multiplier
export var dash_fade_duration_multiplier := 1.0 \
        setget _set_dash_fade_duration_multiplier
export var dash_cooldown_multiplier := 1.0 \
        setget _set_dash_cooldown_multiplier

export var uses_duration_instead_of_distance_for_edge_weight := true \
        setget _set_uses_duration_instead_of_distance_for_edge_weight
export var additional_edge_weight_offset_override := -1.0 \
        setget _set_additional_edge_weight_offset_override
export var walking_edge_weight_multiplier_override := -1.0 \
        setget _set_walking_edge_weight_multiplier_override
export var climbing_edge_weight_multiplier_override := -1.0 \
        setget _set_climbing_edge_weight_multiplier_override
export var air_edge_weight_multiplier_override := -1.0 \
        setget _set_air_edge_weight_multiplier_override

# --- Other parameters ---

export var max_jump_chain := 1 \
        setget _set_max_jump_chain

# TODO: For some reason, when this is true, we see fewer valid edges. In
#       theory, this shouldn't be the case?
## -   If this is true, then horizontal movement will be applied earlier in a
##     jump rather than later.[br]
## -   That is, if this is true, jump trajectories will be less
##     up-sideways-then-down, and more parabolic and diagonal.[br]
export var minimizes_velocity_change_when_jumping := false \
        setget _set_minimizes_velocity_change_when_jumping
## -   If this is true, then at runtime, after finding a path through
##     build-time-calculated edges, the Navigator will try to optimize the
##     jump-off points of the edges to better account for the direction that the
##     player will be approaching the edge from.[br]
## -   This produces more efficient and natural movement.[br]
## -   The build-time-calculated edge state would only use surface end-points or
##     closest points.[br]
## -   We also take this opportunity to update start velocities to exactly match
##     what is allowed from the ramp-up distance along the edge, rather than
##     either the fixed zero or max-speed value used for the
##     build-time-calculated edge state.[br]
## -   However, these edge calculations can be expensive.[br]
export var optimizes_edge_jump_positions_at_run_time := true \
        setget _set_optimizes_edge_jump_positions_at_run_time
export var optimizes_edge_land_positions_at_run_time := true \
        setget _set_optimizes_edge_land_positions_at_run_time
## -   Optimizing edges can be expensive.[br]
## -   Preselections can be updated very frequently (nearly every frame).[br]
## -   So setting this to true could have a significant performance impact.[br]
## -   However, setting this to false means that the user will see inaccurate
##     trajectories, which could be especially significant if beat-tracking is
##     enabled or path timings are important.[br]
export var also_optimizes_preselection_path := true \
        setget _set_also_optimizes_preselection_path
export var forces_player_position_to_match_edge_at_start := true \
        setget _set_forces_player_position_to_match_edge_at_start
export var forces_player_velocity_to_match_edge_at_start := true \
        setget _set_forces_player_velocity_to_match_edge_at_start
export var forces_player_position_to_match_path_at_end := false \
        setget _set_forces_player_position_to_match_path_at_end
export var forces_player_velocity_to_zero_at_path_end := false \
        setget _set_forces_player_velocity_to_zero_at_path_end
## -   If true, then player position will be forced to match the expected
##     calculated edge-movement position during each frame.[br]
## -   Without this, there is typically some deviation at run-time from the
##     expected calculated edge trajectories.[br]
export var syncs_player_position_to_edge_trajectory := true \
        setget _set_syncs_player_position_to_edge_trajectory
## -   If true, then player velocity will be forced to match the expected
##     calculated edge-movement velocity during each frame.[br]
## -   Without this, there is typically some deviation at run-time from the
##     expected calculated edge trajectories.[br]
export var syncs_player_velocity_to_edge_trajectory := true \
        setget _set_syncs_player_velocity_to_edge_trajectory
## -   If true, then trajectory positions will be stored after performing edge
##     calculations.[br]
## -   This state could be used for drawing path trajectories or updating player
##     positions at runtime.[br]
export var includes_continuous_trajectory_positions := true \
        setget _set_includes_continuous_trajectory_positions
## -   If true, then trajectory velocities will be stored after performing edge
##     calculations.[br]
## -   This state could be used for drawing path trajectories or updating player
##     velocities at runtime.[br]
export var includes_continuous_trajectory_velocities := true \
        setget _set_includes_continuous_trajectory_velocities
## -   If true, then discrete trajectory state will be calculated and saved for
##     each edge.[br]
## -   This "discrete" state should more closely reflect what would be generated
##     by normal player movement at runtime, rather than the "continuous" state,
##     which doesn't take into account the error due to the calculation sampling
##     interval.[br]
export var includes_discrete_trajectory_state := true \
        setget _set_includes_discrete_trajectory_state
## -   If false, then any trajectory state that would have otherwise been stored
##     (according to other MovementParams flags), will not be stored in either
##     the runtime PlatformGraph or in the build-time platform-graph save
##     files.[br]
## -   Omitting this trajectory state from a save file can significantly reduce
##     its size.[br]
## -   If trajectory state is omitted at build time, and is still needed at
##     runtime, then it will be calculated on-the-fly as needed.[br]
export var is_trajectory_state_stored_at_build_time := false \
        setget _set_is_trajectory_state_stored_at_build_time
## -   If true, then the player position will be updated according to
##     pre-calculated edge trajectories, and Godot's physics and collision
##     engine will not be used to update player state.[br]
## -   This also means that the user will not be able to control movement with
##     standard move and jump key-press actions.[br]
export var bypasses_runtime_physics := false \
        setget _set_bypasses_runtime_physics

export var retries_navigation_when_interrupted := true \
        setget _set_retries_navigation_when_interrupted
export var min_intra_surface_distance_to_optimize_jump_for := 16.0 \
        setget _set_min_intra_surface_distance_to_optimize_jump_for
## -   When calculating possible edges between a given pair of surfaces, we
##     usually need to quit early (for performance) as soon as we've found
##     enough edges, rather than calculate all possible edges.[br]
## -   In order to decide whether to skip edge calculation for a given jump/land
##     point, we look at how far away it is from any other jump/land point that
##     we already found a valid edge for, on the same surface, for the same
##     surface pair.[br]
## -   We use this distance to determine threshold how far away is enough.[br]
export var distance_squared_threshold_for_considering_additional_jump_land_points := 32.0 * 32.0 \
        setget _set_distance_squared_threshold_for_considering_additional_jump_land_points
## -   If true, then edge calculations for a given surface pair will stop early
##     as soon as the first valid edge for the pair is found.[br]
## -   This overrides
##     distance_squared_threshold_for_considering_additional_jump_land_points.[br]
export var stops_after_finding_first_valid_edge_for_a_surface_pair := false \
        setget _set_stops_after_finding_first_valid_edge_for_a_surface_pair
## -   If true, then valid edges will be calculated for every good jump/land
##     position between a given surface pair.[br]
## -   This will take more time to compute.[br]
## -   This overrides
##     distance_squared_threshold_for_considering_additional_jump_land_points.[br]
export var calculates_all_valid_edges_for_a_surface_pair := false \
        setget _set_calculates_all_valid_edges_for_a_surface_pair
## -   If this is true, then extra jump/land position combinations will be
##     considered for every surface pair for all combinations of surface ends
##     between the two surfaces.[br]
## -   This should always be redundant with the more intelligent and efficient
##     jump/land positions combinations.[br]
export var always_includes_jump_land_positions_at_surface_ends := false \
        setget _set_always_includes_jump_land_positions_at_surface_ends
export var includes_redundant_jump_land_positions_with_zero_start_velocity := true \
        setget _set_includes_redundant_jump_land_positions_with_zero_start_velocity
## -   This is a constant increase to all jump durations.[br]
## -   This could make it more likely for edge calculations to succeed earlier,
##     or it could just make the player seem more floaty.[br]
export var normal_jump_instruction_duration_increase := 0.08 \
        setget _set_normal_jump_instruction_duration_increase
## -   This is a constant increase to all jump durations.[br]
## -   Some edge calculations are identified early on as likely needing some
##     additional jump height in order to navigate around intermediate
##     surfaces.[br]
## -   This duration increase is used for those exceptional edge
##     calculations.[br]
export var exceptional_jump_instruction_duration_increase := 0.2 \
        setget _set_exceptional_jump_instruction_duration_increase
## If false, then edge calculations will not try to move around intermediate
## surfaces, which will produce many false negatives.
export var recurses_when_colliding_during_horizontal_step_calculations := true \
        setget _set_recurses_when_colliding_during_horizontal_step_calculations
## If false, then edge calculations will not try to consider higher jump height
## in order to move around intermediate surfaces, which will produce many false
## negatives.
export var backtracks_to_consider_higher_jumps_during_horizontal_step_calculations := true \
        setget _set_backtracks_to_consider_higher_jumps_during_horizontal_step_calculations
## The amount of extra margin to include around the player collision boundary
## when performing collision detection for a given edge calculation.
export var collision_margin_for_edge_calculations := 4.0 \
        setget _set_collision_margin_for_edge_calculations
## The amount of extra margin to include for waypoint offsets, so that the
## player doesn't collide unexpectedly with the surface.
export var collision_margin_for_waypoint_positions := 5.0 \
        setget _set_collision_margin_for_waypoint_positions
## -   Some jump/land posititions are less likely to produce valid movement,
##     simply because of how the surfaces are arranged.[br]
## -   Usually there is another more likely pair for the given surfaces.[br]
## -   However, sometimes such pairs can be valid, and sometimes they can even
##     be the only valid pair for the given surfaces.[br]
export var skips_less_likely_jump_land_positions := false \
        setget _set_skips_less_likely_jump_land_positions
## -   If true, then the navigator will include extra offsets so that paths
##     don't end too close to surface ends, and will dynamically insert extra
##     backtracking edges if the player ends up past a surface end at the end of
##     a path.[br]
## -   This should be unnecessary if forces_player_position_to_match_path_at_end
##     is true.[br]
export var prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets := true \
        setget _set_prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets
## -   If true, then edge calculations will re-use previously calculated
##     intermediate waypoints when attempting to backtrack and use a higher max
##     jump height.[br]
## -   Otherwise, intermediate waypoints are recalculated, which can be more
##     expensive, but could produce slightly more accurate results.[br]
export var reuses_previous_waypoints_when_backtracking_on_jump_height := false \
        setget _set_reuses_previous_waypoints_when_backtracking_on_jump_height
export var asserts_no_preexisting_collisions_during_edge_calculations := false \
        setget _set_asserts_no_preexisting_collisions_during_edge_calculations
## -   If true, then edge calculations will attempt to consider alternate
##     intersection points from shape-casting when calculating collision
##     details, rather than the default point returned from move_and_collide,
##     when the default point corresponds to a very oblique collision angle.[br]
## -   For example, move_and_collide could otherwise detect collisons with the
##     adjacent wall when moving vertically and colliding with the edge of a
##     ceiling.[br]
export var checks_for_alternate_intersection_points_for_very_oblique_collisions := true \
        setget _set_checks_for_alternate_intersection_points_for_very_oblique_collisions
export var oblique_collison_normal_aspect_ratio_threshold_threshold := 10.0 \
        setget _set_oblique_collison_normal_aspect_ratio_threshold_threshold
export var min_valid_frame_count_when_colliding_early_with_expected_surface := 4 \
        setget _set_min_valid_frame_count_when_colliding_early_with_expected_surface
export var reached_in_air_destination_distance_squared_threshold := 16.0 * 16.0 \
        setget _set_reached_in_air_destination_distance_squared_threshold
export var max_edges_to_remove_from_end_of_path_for_optimization_to_in_air_destination := 2 \
        setget _set_max_edges_to_remove_from_end_of_path_for_optimization_to_in_air_destination

export var logs_navigator_events := false \
        setget _set_logs_navigator_events
export var logs_player_actions := false \
        setget _set_logs_player_actions
export var logs_inspector_events := false \
        setget _set_logs_inspector_events
export var logs_computer_player_events := false \
        setget _set_logs_computer_player_events

export var fall_through_floor_velocity_boost := 100.0 \
        setget _set_fall_through_floor_velocity_boost

## -   An EdgeCalculator calculates possible edges between certain types of
##     edge pairs.
## -   For example, JumpFromSurfaceCalculator calculates edges that start from
##     a position along a surfacer, but JumpFromSurfaceCalculator edges may end
##     either along a surface or in the air.
## -   A default set of ActionHandlers is usually assigned based on other
##     movement properties, such as `can_jump`.
export(Array, String) var edge_calculators_override
## -   An ActionHandler updates a player's state each frame, in response to
##     current events and the player's current state.
## -   For example, FloorJumpAction listens for jump events while the player is
##     on the ground, and triggers player jump state accordingly.
## -   A default set of ActionHandlers is usually assigned based on other
##     movement properties, such as `can_jump`.
export(Array, String) var action_handlers_override

# --- Derived parameters ---

var gravity_fast_fall: float
var slow_rise_gravity_multiplier: float
var gravity_slow_rise: float
var rise_double_jump_gravity_multiplier: float

var walk_acceleration: float
var in_air_horizontal_acceleration: float
var climb_up_speed: float
var climb_down_speed: float

var friction_coefficient: float

var jump_boost: float
var wall_jump_horizontal_boost: float
var wall_fall_horizontal_boost: float

var max_horizontal_speed_default: float
var max_vertical_speed: float

var dash_speed_multiplier: float
var dash_vertical_boost: float
var dash_duration: float
var dash_fade_duration: float
var dash_cooldown: float

var additional_edge_weight_offset: float
var walking_edge_weight_multiplier: float
var climbing_edge_weight_multiplier: float
var air_edge_weight_multiplier: float

var floor_jump_max_horizontal_jump_distance: float
var wall_jump_max_horizontal_jump_distance: float
var min_upward_jump_distance: float
var max_upward_jump_distance: float
var time_to_max_upward_jump_distance: float
var distance_to_max_horizontal_speed: float
var distance_to_half_max_horizontal_speed: float
var stopping_distance_on_default_floor_from_max_speed: float

# Array<ActionHandler>
var action_handlers: Array
# Array<EdgeCalculator>
var edge_calculators: Array

var collider_shape: Shape2D \
        setget _set_collider_shape
# In radians.
var collider_rotation: float \
        setget _set_collider_rotation

var collider_half_width_height := Vector2.INF

## -   This shape is used for calculating trajectories that approximate what
##     might normally happen at runtime.[br]
## -   These trajectories could be used both for rendering navigation paths, as
##     well as for updating player positions at runtime.[br]
var fall_from_floor_corner_calc_shape: Shape2D
var fall_from_floor_corner_calc_shape_rotation: float
## -   This shape is used for calculating trajectories that approximate what
##     might normally happen at runtime.[br]
## -   These trajectories could be used both for rendering navigation paths, as
##     well as for updating player positions at runtime.[br]
var climb_over_wall_corner_calc_shape: Shape2D
var climb_over_wall_corner_calc_shape_rotation: float

var _configuration_warning := ""

# ---


func _init() -> void:
    _init_params()
    _init_animator_params()


# FIXME: --------------------- Test this
func get_property_list() -> Array:
    var default_list := .get_property_list()
    for property_config in default_list:
        if property_config.name == "collider_shape" or \
                property_config.name == "collider_rotation":
            property_config.usage = PROPERTY_USAGE_STORAGE
    return default_list


func _init_params() -> void:
    Sc.logger.error("Abstract MovementParams._init_params is not implemented")


func _init_animator_params() -> void:
    Sc.logger.error(
            "Abstract MovementParams._init_animator_params is not implemented")


func _update_parameters() -> void:
    _validate_parameters()
    if _configuration_warning == "":
        _derive_parameters()
    elif Engine.editor_hint:
        update_configuration_warning()
    else:
        Sc.logger.error("Invalid MovementParams configuration: %s" %
                _configuration_warning)


func _validate_parameters() -> void:
    # FIXME: ---------------------------------
    pass


func _derive_parameters() -> void:
    gravity_fast_fall = \
            gravity_multiplier * \
            Su.movement.gravity_default
    slow_rise_gravity_multiplier = \
            gravity_slow_rise_multiplier_multiplier * \
            Su.movement.gravity_slow_rise_multiplier_default
    rise_double_jump_gravity_multiplier = \
            gravity_double_jump_slow_rise_multiplier_multiplier * \
            Su.movement.gravity_double_jump_slow_rise_multiplier_default
    walk_acceleration = \
            walk_acceleration_multiplier * \
            Su.movement.walk_acceleration_default
    in_air_horizontal_acceleration = \
            in_air_horizontal_acceleration_multiplier * \
            Su.movement.in_air_horizontal_acceleration_default
    climb_up_speed = \
            climb_up_speed_multiplier * \
            Su.movement.climb_up_speed_default
    climb_down_speed = \
            climb_down_speed_multiplier * \
            Su.movement.climb_down_speed_default
    friction_coefficient = \
            friction_coefficient_multiplier * \
            Su.movement.friction_coefficient_default
    jump_boost = \
            jump_boost_multiplier * \
            Su.movement.jump_boost_default
    wall_jump_horizontal_boost = \
            wall_jump_horizontal_boost_multiplier * \
            Su.movement.wall_jump_horizontal_boost_default
    wall_fall_horizontal_boost = \
            wall_fall_horizontal_boost_multiplier * \
            Su.movement.wall_fall_horizontal_boost_default
    
    max_horizontal_speed_default = \
            max_horizontal_speed_default_multiplier * \
            Su.movement.max_horizontal_speed_default_default
    max_vertical_speed = \
            max_vertical_speed_multiplier * \
            Su.movement.max_vertical_speed_default
    
    dash_speed_multiplier = \
            dash_speed_multiplier_multiplier * \
            Su.movement.dash_speed_multiplier_default
    dash_vertical_boost = \
            dash_vertical_boost_multiplier * \
            Su.movement.dash_vertical_boost_default
    dash_duration = \
            dash_duration_multiplier * \
            Su.movement.dash_duration_default
    dash_fade_duration = \
            dash_fade_duration_multiplier * \
            Su.movement.dash_fade_duration_default
    dash_cooldown = \
            dash_cooldown_multiplier * \
            Su.movement.dash_cooldown_default
    
    additional_edge_weight_offset = \
            additional_edge_weight_offset_override if \
            additional_edge_weight_offset_override != -1.0 else \
            Su.movement.additional_edge_weight_offset_default
    walking_edge_weight_multiplier = \
            walking_edge_weight_multiplier_override if \
            walking_edge_weight_multiplier_override != -1.0 else \
            Su.movement.walking_edge_weight_multiplier_default
    climbing_edge_weight_multiplier = \
            climbing_edge_weight_multiplier_override if \
            climbing_edge_weight_multiplier_override != -1.0 else \
            Su.movement.climbing_edge_weight_multiplier_default
    air_edge_weight_multiplier = \
            air_edge_weight_multiplier_override if \
            air_edge_weight_multiplier_override != -1.0 else \
            Su.movement.air_edge_weight_multiplier_default
    
    action_handlers = Su.movement.get_action_handlers_from_names(
            action_handlers_override if \
                    action_handlers_override != null else \
                    Su.movement.get_default_action_handler_names(),
            syncs_player_position_to_edge_trajectory or \
                    syncs_player_velocity_to_edge_trajectory)
    edge_calculators = Su.movement.get_edge_calculators_from_names(
            edge_calculators_override if \
            edge_calculators_override != null else \
            Su.movement.get_default_edge_calculator_names())


func _get_configuration_warning() -> String:
    return _configuration_warning


func get_max_horizontal_jump_distance(surface_side: int) -> float:
    return wall_jump_max_horizontal_jump_distance if \
            surface_side == SurfaceSide.LEFT_WALL or \
            surface_side == SurfaceSide.RIGHT_WALL else \
            floor_jump_max_horizontal_jump_distance


func _set_can_grab_walls(value: bool) -> void:
    can_grab_walls = value
    _update_parameters()


func _set_can_grab_ceilings(value: bool) -> void:
    can_grab_ceilings = value
    _update_parameters()


func _set_can_jump(value: bool) -> void:
    can_jump = value
    _update_parameters()


func _set_can_dash(value: bool) -> void:
    can_dash = value
    _update_parameters()


func _set_can_double_jump(value: bool) -> void:
    can_double_jump = value
    _update_parameters()


func _set_gravity_multiplier(value: float) -> void:
    gravity_multiplier = value
    _update_parameters()


func _set_gravity_slow_rise_multiplier_multiplier(value: float) -> void:
    gravity_slow_rise_multiplier_multiplier = value
    _update_parameters()


func _set_gravity_double_jump_slow_rise_multiplier_multiplier(value: float) -> void:
    gravity_double_jump_slow_rise_multiplier_multiplier = value
    _update_parameters()


func _set_walk_acceleration_multiplier(value: float) -> void:
    walk_acceleration_multiplier = value
    _update_parameters()


func _set_in_air_horizontal_acceleration_multiplier(value: float) -> void:
    in_air_horizontal_acceleration_multiplier = value
    _update_parameters()


func _set_climb_up_speed_multiplier(value: float) -> void:
    climb_up_speed_multiplier = value
    _update_parameters()


func _set_climb_down_speed_multiplier(value: float) -> void:
    climb_down_speed_multiplier = value
    _update_parameters()


func _set_friction_coefficient_multiplier(value: float) -> void:
    friction_coefficient_multiplier = value
    _update_parameters()


func _set_jump_boost_multiplier(value: float) -> void:
    jump_boost_multiplier = value
    _update_parameters()


func _set_wall_jump_horizontal_boost_multiplier(value: float) -> void:
    wall_jump_horizontal_boost_multiplier = value
    _update_parameters()


func _set_wall_fall_horizontal_boost_multiplier(value: float) -> void:
    wall_fall_horizontal_boost_multiplier = value
    _update_parameters()


func _set_max_horizontal_speed_default_multiplier(value: float) -> void:
    max_horizontal_speed_default_multiplier = value
    _update_parameters()


func _set_max_vertical_speed_multiplier(value: float) -> void:
    max_vertical_speed_multiplier = value
    _update_parameters()


func _set_dash_speed_multiplier_multiplier(value: float) -> void:
    dash_speed_multiplier_multiplier = value
    _update_parameters()


func _set_dash_vertical_boost_multiplier(value: float) -> void:
    dash_vertical_boost_multiplier = value
    _update_parameters()


func _set_dash_duration_multiplier(value: float) -> void:
    dash_duration_multiplier = value
    _update_parameters()


func _set_dash_fade_duration_multiplier(value: float) -> void:
    dash_fade_duration_multiplier = value
    _update_parameters()


func _set_dash_cooldown_multiplier(value: float) -> void:
    dash_cooldown_multiplier = value
    _update_parameters()


func _set_uses_duration_instead_of_distance_for_edge_weight(value: bool) -> void:
    uses_duration_instead_of_distance_for_edge_weight = value
    _update_parameters()


func _set_additional_edge_weight_offset_override(value: float) -> void:
    additional_edge_weight_offset_override = value
    _update_parameters()


func _set_walking_edge_weight_multiplier_override(value: float) -> void:
    walking_edge_weight_multiplier_override = value
    _update_parameters()


func _set_climbing_edge_weight_multiplier_override(value: float) -> void:
    climbing_edge_weight_multiplier_override = value
    _update_parameters()


func _set_air_edge_weight_multiplier_override(value: float) -> void:
    air_edge_weight_multiplier_override = value
    _update_parameters()


func _set_max_jump_chain(value: int) -> void:
    max_jump_chain = value
    _update_parameters()


func _set_minimizes_velocity_change_when_jumping(value: bool) -> void:
    minimizes_velocity_change_when_jumping = value
    _update_parameters()


func _set_optimizes_edge_jump_positions_at_run_time(value: bool) -> void:
    optimizes_edge_jump_positions_at_run_time = value
    _update_parameters()


func _set_optimizes_edge_land_positions_at_run_time(value: bool) -> void:
    optimizes_edge_land_positions_at_run_time = value
    _update_parameters()


func _set_also_optimizes_preselection_path(value: bool) -> void:
    also_optimizes_preselection_path = value
    _update_parameters()


func _set_forces_player_position_to_match_edge_at_start(value: bool) -> void:
    forces_player_position_to_match_edge_at_start = value
    _update_parameters()


func _set_forces_player_velocity_to_match_edge_at_start(value: bool) -> void:
    forces_player_velocity_to_match_edge_at_start = value
    _update_parameters()


func _set_forces_player_position_to_match_path_at_end(value: bool) -> void:
    forces_player_position_to_match_path_at_end = value
    _update_parameters()


func _set_forces_player_velocity_to_zero_at_path_end(value: bool) -> void:
    forces_player_velocity_to_zero_at_path_end = value
    _update_parameters()


func _set_syncs_player_position_to_edge_trajectory(value: bool) -> void:
    syncs_player_position_to_edge_trajectory = value
    _update_parameters()


func _set_syncs_player_velocity_to_edge_trajectory(value: bool) -> void:
    syncs_player_velocity_to_edge_trajectory = value
    _update_parameters()


func _set_includes_continuous_trajectory_positions(value: bool) -> void:
    includes_continuous_trajectory_positions = value
    _update_parameters()


func _set_includes_continuous_trajectory_velocities(value: bool) -> void:
    includes_continuous_trajectory_velocities = value
    _update_parameters()


func _set_includes_discrete_trajectory_state(value: bool) -> void:
    includes_discrete_trajectory_state = value
    _update_parameters()


func _set_is_trajectory_state_stored_at_build_time(value: bool) -> void:
    is_trajectory_state_stored_at_build_time = value
    _update_parameters()


func _set_bypasses_runtime_physics(value: bool) -> void:
    bypasses_runtime_physics = value
    _update_parameters()


func _set_retries_navigation_when_interrupted(value: bool) -> void:
    retries_navigation_when_interrupted = value
    _update_parameters()


func _set_min_intra_surface_distance_to_optimize_jump_for(value: float) -> void:
    min_intra_surface_distance_to_optimize_jump_for = value
    _update_parameters()


func _set_distance_squared_threshold_for_considering_additional_jump_land_points(value: float) -> void:
    distance_squared_threshold_for_considering_additional_jump_land_points = value
    _update_parameters()


func _set_stops_after_finding_first_valid_edge_for_a_surface_pair(value: bool) -> void:
    stops_after_finding_first_valid_edge_for_a_surface_pair = value
    _update_parameters()


func _set_calculates_all_valid_edges_for_a_surface_pair(value: bool) -> void:
    calculates_all_valid_edges_for_a_surface_pair = value
    _update_parameters()


func _set_always_includes_jump_land_positions_at_surface_ends(value: bool) -> void:
    always_includes_jump_land_positions_at_surface_ends = value
    _update_parameters()


func _set_includes_redundant_jump_land_positions_with_zero_start_velocity(value: bool) -> void:
    includes_redundant_jump_land_positions_with_zero_start_velocity = value
    _update_parameters()


func _set_normal_jump_instruction_duration_increase(value: float) -> void:
    normal_jump_instruction_duration_increase = value
    _update_parameters()


func _set_exceptional_jump_instruction_duration_increase(value: float) -> void:
    exceptional_jump_instruction_duration_increase = value
    _update_parameters()


func _set_recurses_when_colliding_during_horizontal_step_calculations(value: bool) -> void:
    recurses_when_colliding_during_horizontal_step_calculations = value
    _update_parameters()


func _set_backtracks_to_consider_higher_jumps_during_horizontal_step_calculations(value: bool) -> void:
    backtracks_to_consider_higher_jumps_during_horizontal_step_calculations = value
    _update_parameters()


func _set_collision_margin_for_edge_calculations(value: float) -> void:
    collision_margin_for_edge_calculations = value
    _update_parameters()


func _set_collision_margin_for_waypoint_positions(value: float) -> void:
    collision_margin_for_waypoint_positions = value
    _update_parameters()


func _set_skips_less_likely_jump_land_positions(value: bool) -> void:
    skips_less_likely_jump_land_positions = value
    _update_parameters()


func _set_prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets(value: bool) -> void:
    prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets = value
    _update_parameters()


func _set_reuses_previous_waypoints_when_backtracking_on_jump_height(value: bool) -> void:
    reuses_previous_waypoints_when_backtracking_on_jump_height = value
    _update_parameters()


func _set_asserts_no_preexisting_collisions_during_edge_calculations(value: bool) -> void:
    asserts_no_preexisting_collisions_during_edge_calculations = value
    _update_parameters()


func _set_checks_for_alternate_intersection_points_for_very_oblique_collisions(value: bool) -> void:
    checks_for_alternate_intersection_points_for_very_oblique_collisions = value
    _update_parameters()


func _set_oblique_collison_normal_aspect_ratio_threshold_threshold(value: float) -> void:
    oblique_collison_normal_aspect_ratio_threshold_threshold = value
    _update_parameters()


func _set_min_valid_frame_count_when_colliding_early_with_expected_surface(value: int) -> void:
    min_valid_frame_count_when_colliding_early_with_expected_surface = value
    _update_parameters()


func _set_reached_in_air_destination_distance_squared_threshold(value: float) -> void:
    reached_in_air_destination_distance_squared_threshold = value
    _update_parameters()


func _set_max_edges_to_remove_from_end_of_path_for_optimization_to_in_air_destination(value: int) -> void:
    max_edges_to_remove_from_end_of_path_for_optimization_to_in_air_destination = value
    _update_parameters()


func _set_logs_navigator_events(value: bool) -> void:
    logs_navigator_events = value
    _update_parameters()


func _set_logs_player_actions(value: bool) -> void:
    logs_player_actions = value
    _update_parameters()


func _set_logs_inspector_events(value: bool) -> void:
    logs_inspector_events = value
    _update_parameters()


func _set_logs_computer_player_events(value: bool) -> void:
    logs_computer_player_events = value
    _update_parameters()


func _set_fall_through_floor_velocity_boost(value: float) -> void:
    fall_through_floor_velocity_boost = value
    _update_parameters()


func _set_collider_shape(value: Shape2D) -> void:
    collider_shape = value
    _update_parameters()


func _set_collider_rotation(value: float) -> void:
    collider_rotation = value
    _update_parameters()
