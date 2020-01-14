# Parameters that are used for calculating edge instructions.
# FIXME: --A ********* doc
extends Reference
class_name MovementCalcResults

# All of the horizontal steps for this local branch of movement.
# Array<MovementCalcStep>
var horizontal_steps: Array

# The single vertical step for this overall jump movement.
var vertical_step: MovementVertCalcStep

# Whether we had to use backtracking to satisfy constraints around intermediate colliding surfaces.
var backtracked_for_new_jump_height: bool

func _init(horizontal_steps: Array, vertical_step: MovementVertCalcStep) -> void:
    self.horizontal_steps = horizontal_steps
    self.vertical_step = vertical_step
    self.backtracked_for_new_jump_height = false
