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

# Whether this constraint is the origin for the overall movement.
var is_origin := false

# Whether this constraint is the destination for the overall movement.
var is_destination := false

# The time at which movement should pass through this constraint.
var time_passing_through := INF

# The minimum possible x velocity when passing through this constraint.
var min_x_velocity := INF

# The maximum possible x velocity when passing through this constraint.
var max_x_velocity := INF

func _init(surface: Surface, position: Vector2, passing_vertically: bool, \
        should_stay_on_min_side: bool) -> void:
    self.surface = surface
    self.position = position
    self.passing_vertically = passing_vertically
    self.should_stay_on_min_side = should_stay_on_min_side
