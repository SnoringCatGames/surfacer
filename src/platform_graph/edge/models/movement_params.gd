tool
class_name MovementParams, \
"res://addons/scaffolder/assets/images/editor_icons/scaffolder_placeholder.png"
extends Node2D


# FIXME: ---------------------
#export var name: String

# FIXME: ---------------------
# String|PackedScene
#var player_path_or_scene

# FIXME: ---------------------
#var animator_params: PlayerAnimatorParams

# Array<String>
export var edge_calculator_names: Array
# Array<String>
export var action_handler_names: Array

export var can_grab_walls := false
export var can_grab_ceilings := false
var can_grab_floors := true
export var can_jump := true
export var can_dash := false
export var can_double_jump := false

export var collider_shape: Shape2D
# In radians.
export var collider_rotation: float
var collider_half_width_height := Vector2.INF

# Array<String>
export var collision_detection_layers := []
# Array<{layer_name: String, radius: float}|
#       {layer_name: String, shape: Shape2D, rotation: float}>
export var proximity_entered_detection_layers := []
# Array<{layer_name: String, radius: float}|
#       {layer_name: String, shape: Shape2D, rotation: float}>
export var proximity_exited_detection_layers := []

# -   This shape is used for calculating trajectories that approximate what
#     might normally happen at runtime.
# -   These trajectories could be used both for rendering navigation paths, as
#     well as for updating player positions at runtime.
export var fall_from_floor_corner_calc_shape: Shape2D
export var fall_from_floor_corner_calc_shape_rotation: float
# -   This shape is used for calculating trajectories that approximate what
#     might normally happen at runtime.
# -   These trajectories could be used both for rendering navigation paths, as
#     well as for updating player positions at runtime.
export var climb_over_wall_corner_calc_shape: Shape2D
export var climb_over_wall_corner_calc_shape_rotation: float

export var gravity_fast_fall: float
export var slow_rise_gravity_multiplier: float
export var gravity_slow_rise: float
export var rise_double_jump_gravity_multiplier: float

export var jump_boost: float
export var in_air_horizontal_acceleration: float
export var max_jump_chain: int
export var wall_jump_horizontal_boost: float
export var wall_fall_horizontal_boost := 20.0

export var walk_acceleration: float
export var climb_up_speed: float
export var climb_down_speed: float

# -   If this is true, then horizontal movement will be applied earlier in a
#     jump rather than later.
# -   That is, if this is true, jump trajectories will be less
#     up-sideways-then-down, and more parabolic and diagonal.
# TODO: For some reason, when this is true, we see fewer valid edges. In
#       theory, this shouldn't be the case?
export var minimizes_velocity_change_when_jumping := true
# -   If this is true, then at runtime, after finding a path through
#     build-time-calculated edges, the Navigator will try to optimize the
#     jump-off points of the edges to better account for the direction that the
#     player will be approaching the edge from.
# -   This produces more efficient and natural movement.
# -   The build-time-calculated edge state would only use surface end-points or
#     closest points.
# -   We also take this opportunity to update start velocities to exactly match
#     what is allowed from the ramp-up distance along the edge, rather than
#     either the fixed zero or max-speed value used for the
#     build-time-calculated edge state.
# -   However, these edge calculations can be expensive.
export var optimizes_edge_jump_positions_at_run_time := false
export var optimizes_edge_land_positions_at_run_time := false
# -   Optimizing edges can be expensive.
# -   Preselections can be updated very frequently (nearly every frame).
# -   So setting this to true could have a significant performance impact.
# -   However, setting this to false means that the user will see inaccurate
#     trajectories, which could be especially significant if beat-tracking is
#     enabled or path timings are important.
export var also_optimizes_preselection_path := false
export var forces_player_position_to_match_edge_at_start := false
export var forces_player_velocity_to_match_edge_at_start := false
export var forces_player_position_to_match_path_at_end := false
export var forces_player_velocity_to_zero_at_path_end := false
# -   If true, then player position will be forced to match the expected
#     calculated edge-movement position during each frame.
# -   Without this, there is typically some deviation at run-time from the
#     expected calculated edge trajectories.
export var syncs_player_position_to_edge_trajectory := false
# -   If true, then player velocity will be forced to match the expected
#     calculated edge-movement velocity during each frame.
# -   Without this, there is typically some deviation at run-time from the
#     expected calculated edge trajectories.
export var syncs_player_velocity_to_edge_trajectory := false
# -   If true, then trajectory positions will be stored after performing edge
#     calculations.
# -   This state could be used for drawing path trajectories or updating player
#     positions at runtime.
export var includes_continuous_trajectory_positions := true
# -   If true, then trajectory velocities will be stored after performing edge
#     calculations.
# -   This state could be used for drawing path trajectories or updating player
#     velocities at runtime.
export var includes_continuous_trajectory_velocities := true
# -   If true, then discrete trajectory state will be calculated and saved for
#     each edge.
# -   This "discrete" state should more closely reflect what would be generated
#     by normal player movement at runtime, rather than the "continuous" state,
#     which doesn't take into account the error due to the calculation sampling
#     interval.
export var includes_discrete_trajectory_state := true
# -   If false, then any trajectory state that would have otherwise been stored
#     (according to other MovementParams flags), will not be stored in either
#     the runtime PlatformGraph or in the build-time platform-graph save files.
# -   Omitting this trajectory state from a save file can significantly reduce
#     its size.
# -   If trajectory state is omitted at build time, and is still needed at
#     runtime, then it will be calculated on-the-fly as needed.
export var is_trajectory_state_stored_at_build_time := true
# -   If true, then the player position will be updated according to
#     pre-calculated edge trajectories, and Godot's physics and collision
#     engine will not be used to update player state.
# -   This also means that the user will not be able to control movement with
#     standard move and jump key-press actions.
export var bypasses_runtime_physics := false

export var retries_navigation_when_interrupted := true
export var min_intra_surface_distance_to_optimize_jump_for := 16.0
# -   When calculating possible edges between a given pair of surfaces, we
#     usually need to quit early (for performance) as soon as we've found
#     enough edges, rather than calculate all possible edges.
# -   In order to decide whether to skip edge calculation for a given jump/land
#     point, we look at how far away it is from any other jump/land point that
#     we already found a valid edge for, on the same surface, for the same
#     surface pair.
# -   We use this distance to determine threshold how far away is enough.
export var distance_squared_threshold_for_considering_additional_jump_land_points := \
        128.0 * 128.0
# -   If true, then edge calculations for a given surface pair will stop early
#     as soon as the first valid edge for the pair is found.
# -   This overrides
#     distance_squared_threshold_for_considering_additional_jump_land_points.
export var stops_after_finding_first_valid_edge_for_a_surface_pair := false
# -   If true, then valid edges will be calculated for every good jump/land
#     position between a given surface pair.
# -   This will take more time to compute.
# -   This overrides
#     distance_squared_threshold_for_considering_additional_jump_land_points.
export var calculates_all_valid_edges_for_a_surface_pair := false
# -   If this is true, then extra jump/land position combinations will be
#     considered for every surface pair for all combinations of surface ends
#     between the two surfaces.
# -   This should always be redundant with the more intelligent and efficient
#     jump/land positions combinations.
export var always_includes_jump_land_positions_at_surface_ends := false
export var includes_redundant_jump_land_positions_with_zero_start_velocity := false
# -   This is a constant increase to all jump durations.
# -   This could make it more likely for edge calculations to succeed earlier,
#     or it could just make the player seem more floaty.
export var normal_jump_instruction_duration_increase := 0.08
# -   This is a constant increase to all jump durations.
# -   Some edge calculations are identified early on as likely needing some
#     additional jump height in order to navigate around intermediate surfaces.
# -   This duration increase is used for those exceptional edge calculations.
export var exceptional_jump_instruction_duration_increase := 0.2
# If false, then edge calculations will not try to move around intermediate
# surfaces, which will produce many false negatives.
export var recurses_when_colliding_during_horizontal_step_calculations := true
# If false, then edge calculations will not try to consider higher jump height
# in order to move around intermediate surfaces, which will produce many false
# negatives.
export var backtracks_to_consider_higher_jumps_during_horizontal_step_calculations := \
        true
# The amount of extra margin to include around the player collision boundary
# when performing collision detection for a given edge calculation.
export var collision_margin_for_edge_calculations := 1.0
# The amount of extra margin to include for waypoint offsets, so that the
# player doesn't collide unexpectedly with the surface.
export var collision_margin_for_waypoint_positions := 1.25
# -   Some jump/land posititions are less likely to produce valid movement,
#     simply because of how the surfaces are arranged.
# -   Usually there is another more likely pair for the given surfaces.
# -   However, sometimes such pairs can be valid, and sometimes they can even
#     be the only valid pair for the given surfaces.
export var skips_less_likely_jump_land_positions := false
# -   If true, then the navigator will include extra offsets so that paths
#     don't end too close to surface ends, and will dynamically insert extra
#     backtracking edges if the player ends up past a surface end at the end of
#     a path.
# -   This should be unnecessary if forces_player_position_to_match_path_at_end
#     is true.
export var prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets := \
        false
# -   If true, then edge calculations will re-use previously calculated
#     intermediate waypoints when attempting to backtrack and use a higher max
#     jump height.
# -   Otherwise, intermediate waypoints are recalculated, which can be more
#     expensive, but could produce slightly more accurate results.
export var reuses_previous_waypoints_when_backtracking_on_jump_height := true
export var asserts_no_preexisting_collisions_during_edge_calculations := true
# -   If true, then edge calculations will attempt to consider alternate
#     intersection points from shape-casting when calculating collision
#     details, rather than the default point returned from move_and_collide,
#     when the default point corresponds to a very oblique collision angle.
# -   For example, move_and_collide could otherwise detect collisons with the
#     adjacent wall when moving vertically and colliding with the edge of a
#     ceiling.
export var checks_for_alternate_intersection_points_for_very_oblique_collisions := \
        true
export var oblique_collison_normal_aspect_ratio_threshold_threshold := 10.0
export var min_valid_frame_count_when_colliding_early_with_expected_surface := 4
export var reached_in_air_destination_distance_squared_threshold := 16.0 * 16.0
export var max_edges_to_remove_from_end_of_path_for_optimization_to_in_air_destination := 2

export var logs_navigator_events := false
export var logs_player_actions := false
export var logs_inspector_events := false
export var logs_computer_player_events := false

export var max_horizontal_speed_default: float
export var min_horizontal_speed: float
export var max_vertical_speed: float
export var min_vertical_speed: float

export var fall_through_floor_velocity_boost: float

export var dash_speed_multiplier: float
export var dash_vertical_boost: float
export var dash_duration: float
export var dash_fade_duration: float
export var dash_cooldown: float

export var floor_jump_max_horizontal_jump_distance: float
export var wall_jump_max_horizontal_jump_distance: float
export var min_upward_jump_distance: float
export var max_upward_jump_distance: float
export var time_to_max_upward_jump_distance: float
export var distance_to_max_horizontal_speed: float
export var distance_to_half_max_horizontal_speed: float
export var stopping_distance_on_default_floor_from_max_speed: float

export var friction_coefficient: float

export var uses_duration_instead_of_distance_for_edge_weight := false
export var additional_edge_weight_offset := 0.0
export var walking_edge_weight_multiplier := 1.0
export var climbing_edge_weight_multiplier := 1.0
export var air_edge_weight_multiplier := 1.0


func _init() -> void:
    _init_params()
    _init_animator_params()


func _init_params() -> void:
    Sc.logger.error("Abstract MovementParams._init_params is not implemented")


func _init_animator_params() -> void:
    Sc.logger.error(
            "Abstract MovementParams._init_animator_params is not implemented")


func get_max_horizontal_jump_distance(surface_side: int) -> float:
    return wall_jump_max_horizontal_jump_distance if \
            surface_side == SurfaceSide.LEFT_WALL or \
            surface_side == SurfaceSide.RIGHT_WALL else \
            floor_jump_max_horizontal_jump_distance
