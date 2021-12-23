class_name EdgeStepCalcResultType


enum {
    MOVEMENT_VALID,
    TARGET_OUT_OF_REACH,
    ALREADY_BACKTRACKED_FOR_SURFACE,
    REDUNDANT_RECURSIVE_COLLISION,
    RECURSION_VALID,
    UNABLE_TO_BACKTRACK,
    BACKTRACKING_VALID,
    BACKTRACKING_INVALID,
    INVALID_COLLISON_STATE,
    EXPECTED_SURFACE_BUT_TOO_FEW_FRAMES,
    CONFIGURED_TO_SKIP_RECURSION,
    CONFIGURED_TO_SKIP_BACKTRACKING,
    UNKNOWN,
}


static func get_string(result: int) -> String:
    match result:
        MOVEMENT_VALID:
            return "MOVEMENT_VALID"
        TARGET_OUT_OF_REACH:
            return "TARGET_OUT_OF_REACH"
        ALREADY_BACKTRACKED_FOR_SURFACE:
            return "ALREADY_BACKTRACKED_FOR_SURFACE"
        REDUNDANT_RECURSIVE_COLLISION:
            return "REDUNDANT_RECURSIVE_COLLISION"
        RECURSION_VALID:
            return "RECURSION_VALID"
        UNABLE_TO_BACKTRACK:
            return "UNABLE_TO_BACKTRACK"
        BACKTRACKING_VALID:
            return "BACKTRACKING_VALID"
        BACKTRACKING_INVALID:
            return "NO_RESULTS_FROM_BACKTRACKING"
        INVALID_COLLISON_STATE:
            return "INVALID_COLLISON_STATE"
        EXPECTED_SURFACE_BUT_TOO_FEW_FRAMES:
            return "EXPECTED_SURFACE_BUT_TOO_FEW_FRAMES"
        CONFIGURED_TO_SKIP_RECURSION:
            return "CONFIGURED_TO_SKIP_RECURSION"
        CONFIGURED_TO_SKIP_BACKTRACKING:
            return "CONFIGURED_TO_SKIP_BACKTRACKING"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Sc.logger.error("Invalid EdgeStepCalcResultType: %s" % result)
            return "UNKNOWN"


static func to_description_list(result: int) -> Array:
    match result:
        MOVEMENT_VALID:
            return [
                "Movement is valid.",
            ]
        TARGET_OUT_OF_REACH:
            return [
                "The target is out of reach.",
            ]
        ALREADY_BACKTRACKED_FOR_SURFACE:
            return [
                "Hit an intermediate surface.",
                ("We considered this surface when backtracking to consider" +
                "\n                a new max jump height after colliding."),
            ]
        REDUNDANT_RECURSIVE_COLLISION:
            return [
                "Hit an intermediate surface.",
                ("We already considered waypoints around this surface in " +
                "\n                the parent step."),
            ]
        RECURSION_VALID:
            return [
                "Hit an intermediate surface.",
                ("Valid movement was found when recursing to consider " +
                        "separate" +
                "\n                movement to/from an intermediate " +
                        "waypoint."),
            ]
        UNABLE_TO_BACKTRACK:
            return [
                "Hit an intermediate surface.",
                ("Valid movement was not found when recursing to consider " +
                        "separate" +
                "\n                movement to/from an intermediate " +
                        "waypoint, and backtracking " +
                "\n                to consider a new max jump height " +
                        "isn't possible."),
            ]
        BACKTRACKING_VALID:
            return [
                "Hit an intermediate surface.",
                ("Valid movement was found when backtracking to consider " +
                "\n                a new max jump height."),
            ]
        BACKTRACKING_INVALID:
            return [
                "Hit an intermediate surface.",
                ("No valid movement around was found despite backtracking" +
                "\n                to consider a new max jump height."),
            ]
        INVALID_COLLISON_STATE:
            return [
                "Invalid collision state.",
            ]
        EXPECTED_SURFACE_BUT_TOO_FEW_FRAMES:
            return [
                "Hit the expected surface, but hit it too quickly.",
            ]
        CONFIGURED_TO_SKIP_RECURSION:
            return [
                "Configured to skip recursion.",
            ]
        CONFIGURED_TO_SKIP_BACKTRACKING:
            return [
                ("Configured to skip backtracking to consider a new " +
                "\n                max jump height."),
            ]
        UNKNOWN:
            return [
                "Unexpected result",
            ]
        _:
            Sc.logger.error("Invalid EdgeStepCalcResultType: %s" % result)
            return [
                "Unexpected result",
            ]
