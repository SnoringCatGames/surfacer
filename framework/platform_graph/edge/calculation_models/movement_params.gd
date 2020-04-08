extends Reference
class_name MovementParams

# TODO: Add defaults for some of these

var name: String

# Array<String>
var movement_calculator_names: Array
# Array<String>
var action_handler_names: Array

var can_grab_walls: bool
var can_grab_ceilings: bool
var can_grab_floors: bool

var collider_shape: Shape2D
# In radians.
var collider_rotation: float
var collider_half_width_height := Vector2.INF

var gravity_fast_fall: float
var slow_rise_gravity_multiplier: float
var gravity_slow_rise: float
var rise_double_jump_gravity_multiplier: float

var jump_boost: float
var in_air_horizontal_acceleration: float
var max_jump_chain: int
var wall_jump_horizontal_boost: float

var walk_acceleration: float
var climb_up_speed: float
var climb_down_speed: float

var minimizes_velocity_change_when_jumping := true
# At runtime, after finding a path through build-time-calculated edges, try to optimize the
# jump-off points of the edges to better account for the direction that the player will be
# approaching the edge from. This produces more efficient and natural movement. The
# build-time-calculated edge state would only use surface end-points or closest points. We also
# take this opportunity to update start velocities to exactly match what is allowed from the
# ramp-up distance along the edge, rather than either the fixed zero or max-speed value used for
# the build-time-calculated edge state.
var optimizes_edge_jump_positions_at_run_time := false
var optimizes_edge_land_positions_at_run_time := false
var forces_player_position_to_match_edge_at_start := false
var forces_player_velocity_to_match_edge_at_start := false
# If true, then player velocity will be forced to match the expected calculated edge-movement
# velocity during each frame. Without this, there is typically some deviation at run-time from the
# expected calculated edge trajectories.
var syncs_player_velocity_to_edge_trajectory := false
var min_intra_surface_distance_to_optimize_jump_for := 16.0
# When calculating possible edges between a given pair of surfaces, we usually need to quit early 
# (for performance) as soon as we've found enough edges, rather than calculate all possible edges.
# In order to decide whether to skip edge calculation for a given jump/land point, we look at how
# far away it is from any other jump/land point that we already found a valid edge for, on the
# same surface, for the same surface pair. We use this distance to determine threshold how far away
# is enough.
var distance_squared_threshold_for_considering_additional_jump_land_points := 128.0 * 128.0
var always_includes_jump_land_end_point_combinations := false
# This is a constant increase to all jump durations. This could make it more likely for edge
# calculations to succeed earlier, or it could just make the player seem more floaty.
var normal_jump_instruction_duration_increase := 0.08
# This is a constant increase to all jump durations. Some edge calculations are identified early
# on as likely needing some additional jump height in order to navigate around intermediate
# surfaces. This duration increase is used for those exceptional edge calculations.
var exceptional_jump_instruction_duration_increase := 0.2

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

var friction_multiplier: float

var uses_duration_instead_of_distance_for_edge_weight := false
var additional_edge_weight_offset := 0.0
var walking_edge_weight_multiplier := 1.0
var climbing_edge_weight_multiplier := 1.0
var air_edge_weight_multiplier := 1.0

func get_max_horizontal_jump_distance(surface_side: int) -> float:
    return wall_jump_max_horizontal_jump_distance if \
            surface_side == SurfaceSide.LEFT_WALL or \
            surface_side == SurfaceSide.RIGHT_WALL else \
            floor_jump_max_horizontal_jump_distance
