extends Reference
class_name MovementConstraint

# The surface that was collided with.
var surface: Surface

# This point represents the Player's position (i.e., the Player's center), NOT the corner of the
# Surface.
var passing_point: Vector2

# TODO: Remove? Is this needed?
var passing_vertically: bool

# TODO: Remove? Is this needed?
var should_stay_on_min_side: bool

var min_x_velocity := INF

var max_x_velocity := INF

var is_destination: bool

func _init(surface: Surface, passing_point: Vector2, passing_vertically: bool, \
        should_stay_on_min_side: bool, is_destination := false) -> void:
    self.surface = surface
    self.passing_point = passing_point
    self.passing_vertically = passing_vertically
    self.should_stay_on_min_side = should_stay_on_min_side
    self.is_destination = is_destination
