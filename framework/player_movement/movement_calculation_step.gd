# Some start and stop state for a single input command.
# 
# This is used internally to make edge calculation easier. These are converted to
# PlayerInstructions before the edges are finalized and stored.
# 
# Each overall (edge) movement consists of a single vertical step and a series of horizontal steps.
# 
# - A vertical step will always have its jump instruction starting at the same time as the overall
#   step.
# - A vertical step usually will not have its jump instruction ending at the same time as the
#   overall step.
# - A horizontal step may have its move instruction starting after the start of the overall step.
#   - This happens when the step needs to use a step-end x velocity that is greater than the
#     minimum possible.
# - A horizontal step may have its move instruction ending before the overall step.
#   - This happens when the step uses the slowest step-end x velocity possible.
# - A horizontal step will always have either time_instruction_end == time_step_end or
#   time_instruction_start == time_step_start.
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

var horizontal_acceleration_sign: int

var time_step_start: float
var time_instruction_start: float
var time_instruction_end: float
var time_step_end: float

var position_step_start: Vector2
var position_instruction_start: Vector2
var position_instruction_end: Vector2
var position_step_end: Vector2

var velocity_step_start: Vector2
var velocity_instruction_start: Vector2
var velocity_instruction_end: Vector2
var velocity_step_end: Vector2
