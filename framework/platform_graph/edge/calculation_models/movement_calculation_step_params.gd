# Parameters that are used for calculating edge instructions.
# FIXME: --A ********* doc
extends Reference
class_name MovementCalcStepParams

# The start position of this local branch of movement.
var start_waypoint: Waypoint

# The end position of this local branch of movement.
var end_waypoint: Waypoint

# The single vertical step for this overall jump movement.
var vertical_step: MovementVertCalcStep

var step_attempt_debug_results: MovementCalcStepDebugState

func _init( \
        start_waypoint: Waypoint, \
        end_waypoint: Waypoint, \
        vertical_step: MovementVertCalcStep, \
        overall_calc_params: MovementCalcOverallParams, \
        parent_step_calc_params: MovementCalcStepParams, \
        previous_out_of_reach_waypoint: Waypoint) -> void:
    self.start_waypoint = start_waypoint
    self.end_waypoint = end_waypoint
    self.vertical_step = vertical_step
    
    if overall_calc_params.in_debug_mode:
        var step_index := overall_calc_params.edge_attempt_debug_results.total_step_count
        step_attempt_debug_results = MovementCalcStepDebugState.new( \
                self, \
                step_index, \
                overall_calc_params.edge_attempt_debug_results, \
                previous_out_of_reach_waypoint)
        if parent_step_calc_params != null:
            parent_step_calc_params.step_attempt_debug_results.children_step_attempts.push_back( \
                    step_attempt_debug_results)
        else:
            overall_calc_params.edge_attempt_debug_results.children_step_attempts.push_back( \
                    step_attempt_debug_results)
        overall_calc_params.edge_attempt_debug_results.total_step_count += 1
