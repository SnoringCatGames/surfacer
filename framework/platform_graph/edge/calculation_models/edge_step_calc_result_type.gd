class_name EdgeStepCalcResultType

enum {
    MOVEMENT_VALID,
    TARGET_OUT_OF_REACH,
    ALREADY_BACKTRACKED_FOR_SURFACE,
    RECURSION_VALID,
    BACKTRACKING_VALID,
    BACKTRACKING_INVALID,
    INVALID_COLLISON_STATE,
    CONFIGURED_TO_SKIP_RECURSION,
    CONFIGURED_TO_SKIP_BACKTRACKING,
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
        INVALID_COLLISON_STATE:
            return "INVALID_COLLISON_STATE"
        CONFIGURED_TO_SKIP_RECURSION:
            return "CONFIGURED_TO_SKIP_RECURSION"
        CONFIGURED_TO_SKIP_BACKTRACKING:
            return "CONFIGURED_TO_SKIP_BACKTRACKING"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Utils.error("Invalid EdgeStepCalcResultType: %s" % result)
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
        INVALID_COLLISON_STATE:
            return [ \
                "Invalid collision state.", \
            ]
        CONFIGURED_TO_SKIP_RECURSION:
            return [ \
                "Configured to skip recursion.", \
            ]
        CONFIGURED_TO_SKIP_BACKTRACKING:
            return [ \
                "Configured to skip backtracking to consider a new " + \
                "\n                max jump height.", \
            ]
        UNKNOWN:
            return [ \
                "Unexpected result", \
            ]
        _:
            Utils.error("Invalid EdgeStepCalcResultType: %s" % result)
            return [ \
                "Unexpected result", \
            ]
