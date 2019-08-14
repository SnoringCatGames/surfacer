# Parameters that are used for calculating edge instructions.
# FIXME: --A ********* doc
extends Reference
class_name MovementCalcLocalParams

# The start position of this local branch of movement.
var start_constraint: MovementConstraint

# The end position of this local branch of movement.
var end_constraint: MovementConstraint

# The single vertical step for this overall jump movement.
var vertical_step: MovementVertCalcStep

func _init(start_constraint: MovementConstraint, end_constraint: MovementConstraint, \
        vertical_step: MovementVertCalcStep) -> void:
    self.start_constraint = start_constraint
    self.end_constraint = end_constraint
    self.vertical_step = vertical_step
