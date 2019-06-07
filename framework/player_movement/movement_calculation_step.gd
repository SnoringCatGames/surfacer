# Some start and stop state for a single input command. This is used internally to make Edge
# calculation easier. These are converted to PlayerInstructions before the Edges are finalized and
# stored.
extends Reference
class_name MovementCalcStep

var input_key: String
var time_start: float
var time_end: float
var position_start: Vector2
var position_end: Vector2
var velocity_start: Vector2
var velocity_end: Vector2
var horizontal_movement_sign: int
