class_name EdgeCalcResultType

enum {
    EDGE_VALID_WITH_ONE_STEP,
    EDGE_VALID_WITHOUT_INCREASING_JUMP_HEIGHT,
    EDGE_VALID_WITH_INCREASING_JUMP_HEIGHT,
    
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

static func get_string(result_type: int) -> String:
    match result_type:
        EDGE_VALID_WITH_ONE_STEP:
            return "EDGE_VALID_WITH_ONE_STEP"
        EDGE_VALID_WITHOUT_INCREASING_JUMP_HEIGHT:
            return "EDGE_VALID_WITHOUT_INCREASING_JUMP_HEIGHT"
        EDGE_VALID_WITH_INCREASING_JUMP_HEIGHT:
            return "EDGE_VALID_WITH_INCREASING_JUMP_HEIGHT"
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
            Gs.logger.error("Invalid EdgeCalcResultType: %s" % result_type)
            return "UNKNOWN"

static func get_description(result_type: int) -> String:
    match result_type:
        EDGE_VALID_WITH_ONE_STEP:
            return "This edge is valid. It was calculated directly using " + \
                    "a single horizontal step."
        EDGE_VALID_WITHOUT_INCREASING_JUMP_HEIGHT:
            return "This edge is valid. It was calculated with multiple " + \
                    "recursive horizontal steps to/from intermediate " + \
                    "waypoints (around intermediate surface collisions)."
        EDGE_VALID_WITH_INCREASING_JUMP_HEIGHT:
            return "This edge is valid. It was calculated with " + \
                    "backtracking on the jump height in order to overcome " + \
                    "intermediate surface collisions."
        WAYPOINT_INVALID:
            return "This edge is invalid. One of its intermediate " + \
                    "waypoints is invalid."
        OUT_OF_REACH_WHEN_CALCULATING_VERTICAL_STEP:
            return "This edge is invalid. Its vertical step's destination " + \
                    "is out of reach."
        FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS:
            return "This edge is invalid. One of its horizontal steps' " + \
                    "end points is out of reach."
        SKIPPED_FOR_DEBUGGING:
            return "This edge calculation was skipped, because a " + \
                    "debugging configuration filtered it out."
        LESS_LIKELY_TO_BE_VALID:
            return "This edge calculation was abandoned early on, " + \
                    "because it was determined to be less likely to be valid"
        CLOSE_TO_PREVIOUS_EDGE:
            return "This edge is invalid. It is too close to an already " + \
                    "valid edge."
        UNKNOWN:
            return "UNKNOWN"
        _:
            Gs.logger.error("Invalid EdgeCalcResultType: %s" % result_type)
            return "UNKNOWN"

static func get_is_broad_phase_failure(result_type: int) -> bool:
    return result_type != FAILED_WHEN_CALCULATING_HORIZONTAL_STEPS and \
            result_type != EDGE_VALID_WITH_ONE_STEP and \
            result_type != EDGE_VALID_WITHOUT_INCREASING_JUMP_HEIGHT and \
            result_type != EDGE_VALID_WITH_INCREASING_JUMP_HEIGHT

static func get_is_valid(result_type: int) -> bool:
    return result_type == EDGE_VALID_WITH_ONE_STEP or \
            result_type == EDGE_VALID_WITHOUT_INCREASING_JUMP_HEIGHT or \
            result_type == EDGE_VALID_WITH_INCREASING_JUMP_HEIGHT
