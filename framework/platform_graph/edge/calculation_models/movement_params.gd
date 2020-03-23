extends Reference
class_name MovementParams

# TODO: Add defaults for some of these

var can_grab_walls: bool
var can_grab_ceilings: bool
var can_grab_floors: bool

var collider_shape: Shape2D
# In radians.
var collider_rotation: float
var collider_half_width_height := Vector2.INF

var gravity_fast_fall: float
var slow_ascent_gravity_multiplier: float
var gravity_slow_rise: float
var ascent_double_jump_gravity_multiplier: float

var jump_boost: float
var in_air_horizontal_acceleration: float
var max_jump_chain: int
var wall_jump_horizontal_boost: float

var walk_acceleration: float
var climb_up_speed: float
var climb_down_speed: float

var should_minimize_velocity_change_when_jumping: bool
# - In the general case, we can't know at build time what direction along a surface the player will
#   be moving from when they need to start a jump.
# - Unfortunately, using start velocity x values of zero for all jumps edges tends to produce very
#   unnatural composite trajectories (similar to using perpendicular Manhatten distance routes
#   instead of more diagonal routes).
# - So, we can assume that, for surface-end jump-off positions, we'll be approaching the jump-off
#   point from the center of the edge.
# - And for most edges we should have enough run-up distance in order to hit max horizontal speed
#   before reaching the jump-off point--since horizontal acceleration is relatively quick.
# - Also, we only ever consider velocity-start values of zero or max horizontal speed; since the
#   horizontal acceleration is quick, most jumps at run time shouldn't need some medium-speed, and
#   even if they did, we force the initial velocity of the jump to match expected velocity, so the
#   jump trajectory should proceed as expected, and any sudden change in velocity at the jump start
#   should be acceptably small.
var calculates_edges_with_velocity_start_x_max_speed := true
var calculates_edges_from_surface_ends_with_velocity_start_x_zero := false
# At runtime, after finding a path through build-time-calculated edges, try to optimize the
# jump-off points of the edges to better account for the direction that the player will be
# approaching the edge from. This produces more efficient and natural movement. The
# build-time-calculated edge state would only use surface end-points or closest points. We also
# take this opportunity to update start velocities to exactly match what is allowed from the
# ramp-up distance along the edge, rather than either the fixed zero or max-speed value used for
# the build-time-calculated edge state.
var optimizes_edge_jump_offs_at_run_time := false
var forces_player_position_to_match_edge_at_start := false
var forces_player_velocity_to_match_edge_at_start := false
# If true, then player velocity will be forced to match the expected calculated edge-movement
# velocity during each frame. Without this, there is typically some deviation at run-time from the
# expected calculated edge trajectories.
var updates_player_velocity_to_match_edge_trajectory := false
var min_intra_surface_distance_to_optimize_jump_for := 16.0
var considers_closest_mid_point_for_jump_land_position := true
var considers_mid_point_matching_edge_movement_for_jump_land_position := true

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
