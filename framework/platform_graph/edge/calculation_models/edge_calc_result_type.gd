class_name EdgeCalcResultType

enum {
    EDGE_VALID,
    WAYPOINT_INVALID,
    OUT_OF_REACH_WHEN_CALCULATING_VERTICAL_STEP,
    FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS,
    UNKNOWN,
}

static func get_result_string(result: int) -> String:
    match result:
        EDGE_VALID:
            return "EDGE_VALID"
        WAYPOINT_INVALID:
            return "WAYPOINT_INVALID"
        OUT_OF_REACH_WHEN_CALCULATING_VERTICAL_STEP:
            return "OUT_OF_REACH_WHEN_CALCULATING_VERTICAL_STEP"
        FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS:
            return "FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Utils.error("Invalid EdgeCalcResultType: %s" % result)
            return "UNKNOWN"
