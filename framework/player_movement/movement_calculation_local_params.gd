# Parameters that are used for calculating edge instructions.
# FIXME: LEFT OFF HERE: --A ********* doc
extends Reference
class_name MovementCalcLocalParams

# The end position of this local branch of movement.
var position_start: Vector2

# The end position of this local branch of movement.
var position_end: Vector2

# The previous horizontal step before this local branch of movement.
var previous_step: MovementCalcStep

# The single vertical step for this overall jump movement.
var vertical_step: MovementCalcStep

func _init(position_start: Vector2, position_end: Vector2, previous_step: MovementCalcStep, \
        vertical_step: MovementCalcStep) -> void:
    self.position_start = position_start
    self.position_end = position_end
    self.previous_step = previous_step
    self.vertical_step = vertical_step
