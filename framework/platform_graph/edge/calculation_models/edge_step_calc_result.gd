class_name EdgeStepCalcResult

enum {
    MOVEMENT_VALID,
    TARGET_OUT_OF_REACH,
    ALREADY_BACKTRACKED_FOR_SURFACE,
    RECURSION_VALID,
    BACKTRACKING_VALID,
    BACKTRACKING_INVALID,
    UNKNOWN,
}

static func get_result_string(result: int) -> String:
    match result:
        MOVEMENT_VALID:
            return "MOVEMENT_VALID"
        TARGET_OUT_OF_REACH:
            return "TARGET_OUT_OF_REACH"
        ALREADY_BACKTRACKED_FOR_SURFACE:
            return "ALREADY_BACKTRACKED_FOR_SURFACE"
        RECURSION_VALID:
            return "RECURSION_VALID"
        BACKTRACKING_VALID:
            return "BACKTRACKING_VALID"
        BACKTRACKING_INVALID:
            return "NO_RESULTS_FROM_BACKTRACKING"
        UNKNOWN, _:
            return "UNKNOWN"

static func to_description_list(result: int) -> Array:
    match result:
        MOVEMENT_VALID:
            return [ \
                "Movement is valid.", \
            ]
        TARGET_OUT_OF_REACH:
            return [ \
                "The target is out of reach.", \
            ]
        ALREADY_BACKTRACKED_FOR_SURFACE:
            return [ \
                "Hit an intermediate surface.",
                "We considered this surface when backtracking to consider" + \
                "\n                a new max jump height after colliding.", \
            ]
        RECURSION_VALID:
            return [ \
                "Hit an intermediate surface.",
                "Valid movement was found when recursing.", \
            ]
        BACKTRACKING_VALID:
            return [ \
                "Hit an intermediate surface.",
                "Valid movement was found when backtracking.", \
            ]
        BACKTRACKING_INVALID:
            return [ \
                "Hit an intermediate surface.",
                "No valid movement around was found despite backtracking" + \
                "\n                to consider a new max jump height.", \
            ]
        UNKNOWN, _:
            return [ \
                "Unexpected result", \
            ]
