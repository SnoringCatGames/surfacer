# State that captures internal calculation information for a single edge in order to help with
# debugging.
extends Reference
class_name MovementCalcOverallDebugState

var origin_waypoint: Waypoint setget ,_get_origin
var destination_waypoint: Waypoint setget ,_get_destination
var movement_params: MovementParams setget ,_get_movement_params

# Array<MovementCalcStepDebugState>
var children_step_attempts := []

var total_step_count := 0

var failed_before_creating_steps: bool setget ,_get_failed_before_creating_steps

var _overall_calc_params

func _init(overall_calc_params) -> void:
    self._overall_calc_params = overall_calc_params
    
func _get_origin() -> Waypoint:
    return _overall_calc_params.origin_waypoint as Waypoint

func _get_destination() -> Waypoint:
    return _overall_calc_params.destination_waypoint as Waypoint

func _get_movement_params() -> MovementParams:
    return _overall_calc_params.movement_params as MovementParams

func _get_failed_before_creating_steps() -> bool:
    return children_step_attempts.empty() or \
            children_step_attempts.front().step == null
