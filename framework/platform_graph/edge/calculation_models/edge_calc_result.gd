# Parameters that are used for calculating edge instructions.
# FIXME: --A ********* doc
extends Reference
class_name EdgeCalcResult

# All of the horizontal steps for this local branch of movement.
# Array<EdgeStep>
var horizontal_steps: Array

# The single vertical step for this overall jump movement.
var vertical_step: MovementVertCalcStep

# Whether we had to use backtracking to satisfy waypoints around intermediate colliding surfaces.
var backtracked_for_new_jump_height: bool

var edge_calc_params: EdgeCalcParams

func _init( \
        horizontal_steps: Array, \
        vertical_step: MovementVertCalcStep, \
        edge_calc_params: EdgeCalcParams) -> void:
    self.horizontal_steps = horizontal_steps
    self.vertical_step = vertical_step
    self.backtracked_for_new_jump_height = false
    self.edge_calc_params = edge_calc_params
