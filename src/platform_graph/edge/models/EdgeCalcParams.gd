# Parameters that are used for calculating edge instructions.
class_name EdgeCalcParams
extends Reference

var collision_params: CollisionCalcParams

var movement_params: MovementParams

# A margin to extend around the Player's Collider. This helps to compensate for the imprecision
# of these calculations.
var waypoint_offset := Vector2.INF

# The initial velocity for the current edge instructions.
var velocity_start := Vector2.INF

# Whether the jump is likely to need some extra height in order to make it around intermediate
# surface ends before reaching the destination.
var needs_extra_jump_duration: bool

# Whether the jump is likely to need some extra end horizontal velocity in order to ensure we hit
# the land position at the bottom of a wall, rather than falling short.
var needs_extra_wall_land_horizontal_speed: bool

var origin_position: PositionAlongSurface
var destination_position: PositionAlongSurface

# The origin for the current edge instructions.
var origin_waypoint: Waypoint

# The destination for the current edge instructions.
var destination_waypoint: Waypoint

# Whether the calculations for the current edge are allowed to attempt backtracking to consider a
# higher jump.
var can_backtrack_on_height: bool

# Any Surfaces that have previously been hit while calculating the current edge instructions.
# Dictionary<String, bool>
var _collided_surfaces: Dictionary

func _init( \
        collision_params: CollisionCalcParams, \
        origin_position: PositionAlongSurface, \
        destination_position: PositionAlongSurface, \
        origin_waypoint: Waypoint, \
        destination_waypoint: Waypoint, \
        velocity_start: Vector2, \
        needs_extra_jump_duration: bool, \
        needs_extra_wall_land_horizontal_speed: bool, \
        can_backtrack_on_height: bool) -> void:
    self.collision_params = collision_params
    self.movement_params = collision_params.movement_params
    self.origin_position = origin_position
    self.destination_position = destination_position
    self.origin_waypoint = origin_waypoint
    self.destination_waypoint = destination_waypoint
    self.can_backtrack_on_height = can_backtrack_on_height
    self.velocity_start = velocity_start
    self.needs_extra_jump_duration = needs_extra_jump_duration
    self.needs_extra_wall_land_horizontal_speed = needs_extra_wall_land_horizontal_speed
    self.waypoint_offset = \
            movement_params.collider_half_width_height + \
            Vector2(movement_params.collision_margin_for_waypoint_positions, \
                    movement_params.collision_margin_for_waypoint_positions)
    self._collided_surfaces = {}

func have_backtracked_for_surface( \
        surface: Surface, \
        time_jump_release: float) -> bool:
    var key := surface.to_string() + str(time_jump_release)
    return _collided_surfaces.has(key)

func record_backtracked_surface( \
        surface: Surface, \
        time_jump_release: float) -> void:
    var key := surface.to_string() + str(time_jump_release)
    _collided_surfaces[key] = true
