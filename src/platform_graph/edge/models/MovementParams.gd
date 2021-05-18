class_name MovementParams
extends Reference

# TODO: Add defaults for some of these

var name: String

var player_resource_path: String

# Array<String>
var edge_calculator_names: Array
# Array<String>
var action_handler_names: Array

var animator_params: PlayerAnimatorParams

var can_grab_walls: bool
var can_grab_ceilings: bool
var can_grab_floors: bool

var collider_shape: Shape2D
# In radians.
var collider_rotation: float
var collider_half_width_height := Vector2.INF

var fall_from_floor_corner_calc_shape: Shape2D
var fall_from_floor_corner_calc_shape_rotation: float
var climb_over_wall_corner_calc_shape: Shape2D
var climb_over_wall_corner_calc_shape_rotation: float

var gravity_fast_fall: float
var slow_rise_gravity_multiplier: float
var gravity_slow_rise: float
var rise_double_jump_gravity_multiplier: float

var jump_boost: float
var in_air_horizontal_acceleration: float
var max_jump_chain: int
var wall_jump_horizontal_boost: float
var wall_fall_horizontal_boost := 20.0

var walk_acceleration: float
var climb_up_speed: float
var climb_down_speed: float

# If this is true, then horizontal movement will be applied earlier in a jump
# rather than later. That is, jump trajecotries will be more up, sideways, then
# down, and less parabolic and diagonal.
var minimizes_velocity_change_when_jumping := true
# At runtime, after finding a path through build-time-calculated edges, try to
# optimize the jump-off points of the edges to better account for the direction
# that the player will be approaching the edge from. This produces more
# efficient and natural movement. The build-time-calculated edge state would
# only use surface end-points or closest points. We also take this opportunity
# to update start velocities to exactly match what is allowed from the ramp-up
# distance along the edge, rather than either the fixed zero or max-speed value
# used for the build-time-calculated edge state.
var optimizes_edge_jump_positions_at_run_time := false
var optimizes_edge_land_positions_at_run_time := false
var forces_player_position_to_match_edge_at_start := false
var forces_player_velocity_to_match_edge_at_start := false
var forces_player_position_to_match_path_at_end := false
var forces_player_velocity_to_zero_at_path_end := false
# If true, then player position will be forced to match the expected calculated
# edge-movement position during each frame. Without this, there is typically
# some deviation at run-time from the expected calculated edge trajectories.
var syncs_player_position_to_edge_trajectory := false
# If true, then player velocity will be forced to match the expected calculated
# edge-movement velocity during each frame. Without this, there is typically
# some deviation at run-time from the expected calculated edge trajectories.
var syncs_player_velocity_to_edge_trajectory := false
var includes_discrete_frame_state := true
var includes_continuous_frame_positions := true
var includes_continuous_frame_velocities := true
# If true, then the player position will be updated according to pre-calculated
# edge trajectories, and Godot's physics and collision engine will not be used
# to update player state. This also means that the user will not be able to
# control movement with standard move and jump key-press actions.
var bypasses_runtime_physics := false

var retries_navigation_when_interrupted := true
var min_intra_surface_distance_to_optimize_jump_for := 16.0
# When calculating possible edges between a given pair of surfaces, we usually
# need to quit early (for performance) as soon as we've found enough edges,
# rather than calculate all possible edges. In order to decide whether to skip
# edge calculation for a given jump/land point, we look at how far away it is
# from any other jump/land point that we already found a valid edge for, on the
# same surface, for the same surface pair. We use this distance to determine
# threshold how far away is enough.
var distance_squared_threshold_for_considering_additional_jump_land_points := 128.0 * 128.0
# If true, then edge calculations for a given surface pair will stop early as
# soon as the first valid edge for the pair is found. This overrides
# distance_squared_threshold_for_considering_additional_jump_land_points.
var stops_after_finding_first_valid_edge_for_a_surface_pair := false
# If true, then valid edges will be calculated for every good jump/land
# position between a given surface pair. This will take more time to compute.
# This overrides
# distance_squared_threshold_for_considering_additional_jump_land_points.
var calculates_all_valid_edges_for_a_surface_pair := false
# If this is true, then extra jump/land position combinations will be
# considered for every surface pair for all combinations of surface ends
# between the two surfaces. This should always be redundant with the more
# intelligent and efficient jump/land positions combinations.
var always_includes_jump_land_positions_at_surface_ends := false
var includes_redundant_jump_land_positions_with_zero_start_velocity := false
# This is a constant increase to all jump durations. This could make it more
# likely for edge calculations to succeed earlier, or it could just make the
# player seem more floaty.
var normal_jump_instruction_duration_increase := 0.08
# This is a constant increase to all jump durations. Some edge calculations are
# identified early on as likely needing some additional jump height in order to
# navigate around intermediate surfaces. This duration increase is used for
# those exceptional edge calculations.
var exceptional_jump_instruction_duration_increase := 0.2
# If false, then edge calculations will not try to move around intermediate
# surfaces, which will produce many false negatives.
var recurses_when_colliding_during_horizontal_step_calculations := true
# If false, then edge calculations will not try to consider higher jump height
# in order to move around intermediate surfaces, which will produce many false
# negatives.
var backtracks_to_consider_higher_jumps_during_horizontal_step_calculations := true
# The amount of extra margin to include around the player collision boundary
# when performing collision detection for a given edge calculation.
var collision_margin_for_edge_calculations := 1.0
# The amount of extra margin to include for waypoint offsets, so that the
# player doesn't collide unexpectedly with the surface.
var collision_margin_for_waypoint_positions := 1.25
# Some jump/land posititions are less likely to produce valid movement, simply
# because of how the surfaces are arranged. Usually there is another more
# likely pair for the given surfaces. However, sometimes such pairs can be
# valid, and sometimes they can even be the only valid pair for the given
# surfaces.
var skips_less_likely_jump_land_positions := false
# If true, then the navigator will include extra offsets so that paths don't
# end too close to surface ends, and will dynamically insert extra backtracking
# edges if the player ends up past a surface end at the end of a path. This
# should be unnecessary if forces_player_position_to_match_path_at_end is true.
var prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets := false
# If true, then edge calculations will re-use previously calculated
# intermediate waypoints when attempting to backtrack and use a higher max jump
# height. Otherwise, intermediate waypoints are recalculated, which can be more
# expensive, but could produce slightly more accurate results.
var reuses_previous_waypoints_when_backtracking_on_jump_height := true
var asserts_no_preexisting_collisions_during_edge_calculations := true
# If true, then edge calculations will attempt to consider alternate
# intersection points from shape-casting when calculating collision details,
# rather than the default point returned from move_and_collide, when the
# default point corresponds to a very oblique collision angle.
# For example, move_and_collide could otherwise detect collisons with the
# adjacent wall when moving vertically and colliding with the edge of a
# ceiling.
var checks_for_alternate_intersection_points_for_very_oblique_collisions := true
var oblique_collison_normal_aspect_ratio_threshold_threshold := 10.0

var logs_navigator_events := false
var logs_player_actions := false
var logs_inspector_events := false
var logs_computer_player_events := false

var max_horizontal_speed_default: float
var min_horizontal_speed: float
var max_vertical_speed: float
var min_vertical_speed: float

var fall_through_floor_velocity_boost: float

var dash_speed_multiplier: float
var dash_vertical_boost: float
var dash_duration: float
var dash_fade_duration: float
var dash_cooldown: float

var floor_jump_max_horizontal_jump_distance: float
var wall_jump_max_horizontal_jump_distance: float
var min_upward_jump_distance: float
var max_upward_jump_distance: float
var time_to_max_upward_jump_distance: float
var distance_to_max_horizontal_speed: float
var distance_to_half_max_horizontal_speed: float
var stopping_distance_on_default_floor_from_max_speed: float

var friction_coefficient: float

var uses_duration_instead_of_distance_for_edge_weight := false
var additional_edge_weight_offset := 0.0
var walking_edge_weight_multiplier := 1.0
var climbing_edge_weight_multiplier := 1.0
var air_edge_weight_multiplier := 1.0

func _init() -> void:
    _init_params()
    _init_animator_params()

func _init_params() -> void:
    Gs.logger.error("Abstract MovementParams._init_params is not implemented")

func _init_animator_params() -> void:
    Gs.logger.error(
            "Abstract MovementParams._init_animator_params is not implemented")

func get_max_horizontal_jump_distance(surface_side: int) -> float:
    return wall_jump_max_horizontal_jump_distance if \
            surface_side == SurfaceSide.LEFT_WALL or \
            surface_side == SurfaceSide.RIGHT_WALL else \
            floor_jump_max_horizontal_jump_distance
