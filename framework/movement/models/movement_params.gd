extends Reference
class_name MovementParams

# TODO: Add defaults for some of these

var can_grab_walls: bool
var can_grab_ceilings: bool
var can_grab_floors: bool

var collider_shape: Shape2D
var collider_rotation: float
var collider_half_width_height: Vector2

var gravity_fast_fall: float
var slow_ascent_gravity_multiplier: float
var gravity_slow_ascent: float
var ascent_double_jump_gravity_multiplier: float

var jump_boost: float
var in_air_horizontal_acceleration: float
var max_jump_chain: int
var wall_jump_horizontal_multiplier: float

var walk_acceleration: float
var climb_up_speed: float
var climb_down_speed: float

var should_minimize_velocity_change_when_jumping: bool

var max_horizontal_speed_default: float
var current_max_horizontal_speed: float
var min_horizontal_speed: float
var max_vertical_speed: float
var min_vertical_speed: float

var fall_through_floor_velocity_boost: float

var min_speed_to_maintain_vertical_collision: float
var min_speed_to_maintain_horizontal_collision: float

var dash_speed_multiplier: float
var dash_vertical_boost: float
var dash_duration: float
var dash_fade_duration: float
var dash_cooldown: float

var max_horizontal_jump_distance: float
var max_upward_jump_distance: float

var friction_multiplier: float
