# Metadata that captures internal calculation information for a single edge in order to help with
# debugging.
extends Reference
class_name EdgeCalcResultMetadata

var record_calc_details: bool

# EdgeCalcResultType
var edge_calc_result_type := EdgeCalcResultType.UNKNOWN

# WaypointValidity
var waypoint_validity := WaypointValidity.UNKNOWN

# Array<EdgeStepCalcResultMetadata>
var children_step_attempts := []

var total_step_count := 0

var failed_before_creating_steps: bool setget ,_get_failed_before_creating_steps

func _init(record_calc_details: bool) -> void:
    self.record_calc_details = record_calc_details

func _get_failed_before_creating_steps() -> bool:
    return children_step_attempts.empty() or \
            children_step_attempts.front().step == null
