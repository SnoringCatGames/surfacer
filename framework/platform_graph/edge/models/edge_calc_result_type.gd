class_name EdgeCalcResultType

enum {
    EDGE_VALID,
    
    # Narrow-phase failures.
    FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS,
    
    # Broad-phase failures.
    WAYPOINT_INVALID,
    OUT_OF_REACH_WHEN_CALCULATING_VERTICAL_STEP,
    SKIPPED_FOR_DEBUGGING,
    LESS_LIKELY_TO_BE_VALID,
    CLOSE_TO_PREVIOUS_EDGE,
    
    UNKNOWN,
}

static func get_type_string(result_type: int) -> String:
    match result_type:
        EDGE_VALID:
            return "EDGE_VALID"
        WAYPOINT_INVALID:
            return "WAYPOINT_INVALID"
        OUT_OF_REACH_WHEN_CALCULATING_VERTICAL_STEP:
            return "OUT_OF_REACH_WHEN_CALCULATING_VERTICAL_STEP"
        FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS:
            return "FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS"
        SKIPPED_FOR_DEBUGGING:
            return "SKIPPED_FOR_DEBUGGING"
        LESS_LIKELY_TO_BE_VALID:
            return "LESS_LIKELY_TO_BE_VALID"
        CLOSE_TO_PREVIOUS_EDGE:
            return "CLOSE_TO_PREVIOUS_EDGE"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Utils.error("Invalid EdgeCalcResultType: %s" % result_type)
            return "UNKNOWN"

static func get_is_broad_phase_failure(result_type: int) -> bool:
    return result_type != FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS and \
            result_type != EDGE_VALID
