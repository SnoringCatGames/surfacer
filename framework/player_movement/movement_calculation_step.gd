# Some start and stop state for a single input command.
# 
# This is used internally to make edge calculation easier. These are converted to
# PlayerInstructions before the edges are finalized and stored.
# 
# Note: There is an important distinction between the end of the movement step and the end of the
# input instruction within the step:
# - "step_end": The time at which movement should reach the intended destination position for this
#   part of the overall movement. That is, this would either be the overall destination position of
#   the edge, or the start position of the next step.
# - "instruction_end": The time at which the input_key should be released for this step. This is
#   likely to happen before "step_end". If this is a vertical step, then this is the point at which
#   the step starts using fast-fall gravity. If this is a horizontal step, then this is the point
#   at which horizontal acceleration stops.
extends Reference
class_name MovementCalcStep

var input_key: String

var time_start: float

# The time at which the input_key should be released for this step.
var time_instruction_end: float

# The time at which movement for this step should reach the intended destination position for this
# part of the overall movement.
var time_step_end: float

# The time at which movement for this step should reach the maximum height.
# This is only assigned on vertical steps.
var time_peak_height: float

var position_start: Vector2

var position_step_end: Vector2

var position_instruction_end: Vector2

# The maximum height position for this step.
# This is only assigned on vertical steps.
var position_peak_height: Vector2

var velocity_start: Vector2

var velocity_step_end: Vector2

var velocity_instruction_end: Vector2

var horizontal_movement_sign: int
