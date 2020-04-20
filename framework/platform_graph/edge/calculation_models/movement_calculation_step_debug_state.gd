# State that captures internal calculation information for a single (attempted) step within an edge
# in order to help with debugging.
extends Reference
class_name MovementCalcStepDebugState

var start_waypoint: Waypoint setget ,_get_start

var end_waypoint: Waypoint setget ,_get_end

var collision: SurfaceCollision

var collision_debug_state: MovementCalcCollisionDebugState # FIXME: -----------

var result_code := EdgeStepCalcResult.UNKNOWN

var result_code_string: String setget ,_get_result_code_string

var description_list: Array setget ,_get_description_list

var is_backtracking: bool setget ,_get_is_backtracking

var replaced_a_fake: bool setget ,_get_replaced_a_fake

# Array<Waypoint>
var upcoming_waypoints: Array

var previous_out_of_reach_waypoint: Waypoint

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
        previous_out_of_reach_waypoint: Waypoint) -> void:
    self._step_calc_params = _step_calc_params
    self.index = index
    self.overall_debug_state = overall_debug_state
    self.previous_out_of_reach_waypoint = previous_out_of_reach_waypoint

func _get_start() -> Waypoint:
    return _step_calc_params.start_waypoint as Waypoint

func _get_end() -> Waypoint:
    return _step_calc_params.end_waypoint as Waypoint

func _get_result_code_string() -> String:
    return EdgeStepCalcResult.get_result_string(result_code)

func _get_description_list() -> Array:
    return EdgeStepCalcResult.to_description_list(result_code)

func _get_is_backtracking() -> bool:
    return previous_out_of_reach_waypoint != null

func _get_replaced_a_fake() -> bool:
    return _step_calc_params.end_waypoint.replaced_a_fake
