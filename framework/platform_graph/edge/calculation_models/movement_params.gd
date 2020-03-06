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
var forces_player_position_to_match_edge_at_start := true
var forces_player_velocity_to_match_edge_at_start := true
var calculates_edges_from_surface_ends_with_velocity_start_x_zero := false
var calculates_edges_with_velocity_start_x_max_speed := true

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
