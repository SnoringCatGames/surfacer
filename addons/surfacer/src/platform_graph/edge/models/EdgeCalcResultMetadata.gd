# Metadata that captures internal calculation information for a single edge in
# order to help with debugging.
extends Reference
class_name EdgeCalcResultMetadata

var records_calc_details: bool
var records_profile: bool

# EdgeCalcResultType
var edge_calc_result_type := EdgeCalcResultType.UNKNOWN

# WaypointValidity
var waypoint_validity := WaypointValidity.UNKNOWN

# Miscellaneous timings used for profiling calculation performance.
# Dictionary<SurfacerProfilerMetric, Array<float>>
var timings := {}

# Miscellaneous counts used for profiling calculation performance.
# Dictionary<String, int>
var counts := {}

# Array<EdgeStepCalcResultMetadata>
var children_step_attempts := []

var total_step_count := 0

var failed_before_creating_steps: bool setget \
        ,_get_failed_before_creating_steps

func _init( \
        records_calc_details: bool, \
        records_profile: bool) -> void:
    self.records_calc_details = records_calc_details
    self.records_profile = records_profile

func _get_failed_before_creating_steps() -> bool:
    return children_step_attempts.empty()
