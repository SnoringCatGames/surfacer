# State that captures internal calculation information for a single (attempted) step within an edge
# in order to help with debugging.
extends Reference
class_name MovementCalcStepDebugState

var start_constraint: MovementConstraint setget ,_get_start
var end_constraint: MovementConstraint setget ,_get_end

var frame_positions: PoolVector2Array
var collision: SurfaceCollision

var result_code := EdgeStepCalcResult.UNKNOWN
var result_code_string: String setget ,_get_result_code_string
var description: String setget ,_get_description

# MovementCalcStepParams
var _step_calc_params
# Array<MovementCalcStepDebugState>
var children_step_attempts := []

func _init(step_calc_params, parent_step_or_overall_calc_params) -> void:
    self._step_calc_params = step_calc_params
    
    # Children step-calc "nodes" register themselves on their parent.
    parent_step_or_overall_calc_params.debug_state.children_step_attempts.push_back(self)

func _get_start() -> MovementConstraint:
    return _step_calc_params.start_constraint as MovementConstraint

func _get_end() -> MovementConstraint:
    return _step_calc_params.end_constraint as MovementConstraint

func _get_result_code_string() -> String:
    return EdgeStepCalcResult.to_string(result_code)

func _get_description() -> String:
    return EdgeStepCalcResult.to_description_string(result_code)
