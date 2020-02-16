# Parameters that are used for calculating edge instructions.
# FIXME: --A ********* doc
extends Reference
class_name MovementCalcStepParams

# The start position of this local branch of movement.
var start_constraint: MovementConstraint

# The end position of this local branch of movement.
var end_constraint: MovementConstraint

# The single vertical step for this overall jump movement.
var vertical_step: MovementVertCalcStep

var debug_state: MovementCalcStepDebugState

func _init(start_constraint: MovementConstraint, end_constraint: MovementConstraint, \
        vertical_step: MovementVertCalcStep, overall_calc_params: MovementCalcOverallParams, \
        parent_step_calc_params: MovementCalcStepParams, \
        previous_out_of_reach_constraint: MovementConstraint) -> void:
    self.start_constraint = start_constraint
    self.end_constraint = end_constraint
    self.vertical_step = vertical_step
    
    if overall_calc_params.in_debug_mode:
        var step_index := overall_calc_params.debug_state.total_step_count
        debug_state = MovementCalcStepDebugState.new(self, step_index, \
                overall_calc_params.debug_state, previous_out_of_reach_constraint)
        var parent = parent_step_calc_params if parent_step_calc_params != null else \
                overall_calc_params
        parent.debug_state.children_step_attempts.push_back(debug_state)
        overall_calc_params.debug_state.total_step_count += 1
