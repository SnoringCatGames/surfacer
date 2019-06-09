# Parameters that are used for calculating edge instructions.
# FIXME: LEFT OFF HERE: --A ********* doc
extends Reference
class_name MovementCalcResults

# All of the horizontal steps for this local branch of movement.
# Array<MovementCalcStep>
var horizontal_steps: Array

# The single vertical step for this overall jump movement.
var vertical_step: MovementCalcStep

# The total duration of this overall jump movement.
var total_duration: float

func _init(horizontal_steps: Array, vertical_step: MovementCalcStep, \
        total_duration: float) -> void:
    self.horizontal_steps = horizontal_steps
    self.vertical_step = vertical_step
    self.total_duration = total_duration
