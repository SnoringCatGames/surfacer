# A start/end position for movement step calculation.
# 
# This is used internally to make edge calculation easier.
# 
# - For the overall origin/destination points of movement, a constraint could be any point along a
#   surface or any point not along a surface.
# - For all other, intermediate points within a movement, a constraint represents the edge of a
#   surface that the movement must pass through in order to not collide with the surface.
# - Early on, each constraint is assigned a horizontal direction that the movement must travel
#   along when passing through the constraint:
#   - For constraints on left-wall surfaces: The direction of movement must be leftward.
#   - For constraints on right-wall surfaces: The direction of movement must be rightward. 
#   - For constraints on floor/ceiling surfaces, we instead look at whether the constraint is on
#     the left or right side of the surface.
#     - For constraints on the left-side: The direction of movement must be leftward.
#     - For constraints on the right-side: The direction of movement must be rightward.
extends Reference
class_name MovementConstraint

# The surface that was collided with.
var surface: Surface

# This point represents the Player's position (i.e., the Player's center), NOT the corner of the
# Surface.
var position: Vector2

# TODO: Remove? Is this needed?
var passing_vertically: bool

# TODO: Remove? Is this needed?
var should_stay_on_min_side: bool

# The sign of the horizontal movement when passing through this constraint.
var horizontal_movement_sign: int = INF

# The time at which movement should pass through this constraint.
var time_passing_through := INF

# The minimum possible x velocity when passing through this constraint.
var min_x_velocity := INF

# The maximum possible x velocity when passing through this constraint.
var max_x_velocity := INF

# Whether this constraint is the origin for the overall movement.
var is_origin := false

# Whether this constraint is the destination for the overall movement.
var is_destination := false

func _init(surface: Surface, position: Vector2, passing_vertically: bool, \
        should_stay_on_min_side: bool, time_passing_through: float, min_x_velocity: float, \
        max_x_velocity: float) -> void:
    self.surface = surface
    self.position = position
    self.passing_vertically = passing_vertically
    self.should_stay_on_min_side = should_stay_on_min_side
    self.time_passing_through = time_passing_through
    self.min_x_velocity = min_x_velocity
    self.max_x_velocity = max_x_velocity
    
    if horizontal_movement_sign == INF:
        assert(surface != null)
        if surface.side == SurfaceSide.LEFT_WALL:
            self.horizontal_movement_sign = -1
        elif surface.side == SurfaceSide.RIGHT_WALL:
            self.horizontal_movement_sign = 1
        elif should_stay_on_min_side:
            self.horizontal_movement_sign = -1
        else:
            self.horizontal_movement_sign = 1
