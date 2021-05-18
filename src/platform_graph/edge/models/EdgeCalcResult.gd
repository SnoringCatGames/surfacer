# Parameters that are used for calculating edge instructions.
class_name EdgeCalcResult
extends Reference

# All of the horizontal steps for this local branch of movement.
# Array<EdgeStep>
var horizontal_steps: Array

# The single vertical step for this overall jump movement.
var vertical_step: VerticalEdgeStep

# Whether the jump-height was ever increased in order to overcome an
# intermediate collision.
var increased_jump_height := false

var edge_calc_params: EdgeCalcParams

var edge_calc_result_type := EdgeCalcResultType.UNKNOWN

var collision_time := INF

func _init(
        horizontal_steps: Array,
        vertical_step: VerticalEdgeStep,
        edge_calc_params: EdgeCalcParams) -> void:
    self.horizontal_steps = horizontal_steps
    self.vertical_step = vertical_step
    self.increased_jump_height = false
    self.edge_calc_params = edge_calc_params
