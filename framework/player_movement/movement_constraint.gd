extends Reference
class_name MovementConstraint

var passing_point: Vector2
var passing_vertically: bool
var should_stay_on_min_side: bool

func _init(passing_point: Vector2, passing_vertically: bool, \
        should_stay_on_min_side: bool) -> void:
    self.passing_point = passing_point
    self.passing_vertically = passing_vertically
    self.should_stay_on_min_side = should_stay_on_min_side
