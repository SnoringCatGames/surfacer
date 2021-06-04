class_name Waypoint
extends Reference
# A start/end position for movement step calculation.
# 
# This is used internally to make edge calculation easier.
# 
# - For the overall origin/destination points of movement, a waypoint could be any point along a
#   surface or any point not along a surface.
# - For all other, intermediate points within a movement, a waypoint represents the edge of a
#   surface that the movement must pass through in order to not collide with the surface.
# - Early-on during movement calculation, each waypoint is assigned a horizontal direction that
#   the movement must travel along when passing through the waypoint:
#   - For waypoints on left-wall surfaces: The direction of movement must be leftward.
#   - For waypoints on right-wall surfaces: The direction of movement must be rightward.
#   - For waypoints on floor/ceiling surfaces, we instead look at whether the waypoint is on
#     the left or right side of the surface.
#     - For waypoints on the left-side: The direction of movement must be leftward.
#     - For waypoints on the right-side: The direction of movement must be rightward.

# The surface that was collided with.
var surface: Surface

# This point represents the Player's position (i.e., the Player's center), NOT the corner of the
# Surface.
var position := Vector2.INF

var passing_vertically: bool

var should_stay_on_min_side: bool

var previous_waypoint: Waypoint

var next_waypoint: Waypoint

# The sign of the horizontal movement when passing through this waypoint. This is primarily
# calculated according to the surface-side and whether the waypoint is on the min or max side of
# the surface.
var horizontal_movement_sign: int = INF

# The sign of horizontal movement from the previous waypoint to this waypoint. This should
# always agree with the surface-side-based horizontal_movement_sign property, unless this
# waypoint is fake and should be skipped.
var horizontal_movement_sign_from_displacement: int = INF

# The time at which movement should pass through this waypoint.
var time_passing_through := INF

# The minimum possible x velocity when passing through this waypoint.
# 
# This is calculated early-on during movement calculation, and updated as new neighbor waypoints
# get added.
var min_velocity_x := INF

# The maximum possible x velocity when passing through this waypoint.
# 
# This is calculated early-on during movement calculation, and updated as new neighbor waypoints
# get added.
var max_velocity_x := INF

# This is calculated later-onn during movement calculation.
var actual_velocity_x := INF

# Whether the jump is likely to need some extra height in order to make it around intermediate
# surface ends before reaching this destination.
var needs_extra_jump_duration := false

# Whether this waypoint is the origin for the overall movement.
var is_origin := false

# Whether this waypoint is the destination for the overall movement.
var is_destination := false

# Fake waypoints will be skipped by the final overall movement; they only exist as intermediate
# state during movement calculation. They represent a point along an edge of a floor or ceiling
# surface where the horizontal_movement_sign_from_surface differs from the
# horizontal_movement_sign_from_displacement.
# 
# For example, the right-side of a ceiling surface when the jump movement is from the lower-right
# of the edge; in this case, the goal is to skip the ceiling-edge waypoint and moving directly to
# the top-of-the-right-side waypoint.
var is_fake := false

# Whether this was the neighbor waypoint that replaced a fake waypoint.
var replaced_a_fake := false

var validity := WaypointValidity.UNKNOWN

# Whether this waypoint can be reached with the current jump height.
var is_valid: bool setget ,_get_is_valid

var side: int setget ,_get_side


func _init(
        surface: Surface,
        position: Vector2,
        passing_vertically: bool,
        should_stay_on_min_side: bool,
        previous_waypoint: Waypoint,
        next_waypoint: Waypoint) -> void:
    self.surface = surface
    self.position = position
    self.passing_vertically = passing_vertically
    self.should_stay_on_min_side = should_stay_on_min_side
    self.previous_waypoint = previous_waypoint
    self.next_waypoint = next_waypoint


func to_string() -> String:
    return "Waypoint{ %s, passing_vertically: %s, should_stay_on_min_side: %s, surface: %s }" % [
        str(position),
        passing_vertically,
        should_stay_on_min_side,
        surface.to_string(),
    ]


func _get_is_valid() -> bool:
    return validity == WaypointValidity.WAYPOINT_VALID


func _get_side() -> int:
    return surface.side if \
            surface != null else \
            SurfaceSide.NONE
