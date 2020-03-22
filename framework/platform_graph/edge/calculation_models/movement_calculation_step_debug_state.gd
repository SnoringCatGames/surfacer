# State that captures internal calculation information for a single (attempted) step within an edge
# in order to help with debugging.
extends Reference
class_name MovementCalcStepDebugState

var start_constraint: MovementConstraint setget ,_get_start

var end_constraint: MovementConstraint setget ,_get_end

var collision: SurfaceCollision

var collision_debug_state: MovementCalcCollisionDebugState # FIXME: -----------

var result_code := EdgeStepCalcResult.UNKNOWN

var result_code_string: String setget ,_get_result_code_string

var description_list: Array setget ,_get_description_list

var is_backtracking: bool setget ,_get_is_backtracking

var replaced_a_fake: bool setget ,_get_replaced_a_fake

# Array<MovementConstraint>
var upcoming_constraints: Array

var previous_out_of_reach_constraint: MovementConstraint

# MovementCalcStepParams
var _step_calc_params

var step: MovementCalcStep

var index: int

var overall_debug_state: MovementCalcOverallDebugState

# Array<MovementCalcStepDebugState>
var children_step_attempts := []

func _init( \
        _step_calc_params, \
        index: int, \
        overall_debug_state: MovementCalcOverallDebugState, \
        previous_out_of_reach_constraint: MovementConstraint) -> void:
    self._step_calc_params = _step_calc_params
    self.index = index
    self.overall_debug_state = overall_debug_state
    self.previous_out_of_reach_constraint = previous_out_of_reach_constraint

func _get_start() -> MovementConstraint:
    return _step_calc_params.start_constraint as MovementConstraint

func _get_end() -> MovementConstraint:
    return _step_calc_params.end_constraint as MovementConstraint

func _get_result_code_string() -> String:
    return EdgeStepCalcResult.to_string(result_code)

func _get_description_list() -> Array:
    return EdgeStepCalcResult.to_description_list(result_code)

func _get_is_backtracking() -> bool:
    return previous_out_of_reach_constraint != null

func _get_replaced_a_fake() -> bool:
    return _step_calc_params.end_constraint.replaced_a_fake
