class_name WaypointValidity

enum {
    WAYPOINT_VALID,
    FAKE,
    TOO_HIGH,
    OUT_OF_REACH_FROM_ORIGIN,
    OUT_OF_REACH_FROM_ADDITIONAL_HIGH_WAYPOINT,
    THIS_WAYPOINT_OUT_OF_REACH_FROM_PREVIOUS_WAYPOINT,
    TRYING_TO_PASS_OVER_WALL_WHILE_DESCENDING,
    TRYING_TO_PASS_UNDER_WALL_WHILE_ASCENDING,
    NEXT_WAYPOINT_OUT_OF_REACH_FROM_THIS_WAYPOINT,
    NO_VALID_VELOCITY_FROM_ORIGIN,
    NO_VALID_VELOCITY_FOR_NEXT_STEP,
    UNKNOWN,
}

static func get_string(validity: int) -> String:
    match validity:
        WAYPOINT_VALID:
            return "WAYPOINT_VALID"
        FAKE:
            return "FAKE"
        TOO_HIGH:
            return "TOO_HIGH"
        OUT_OF_REACH_FROM_ORIGIN:
            return "OUT_OF_REACH_FROM_ORIGIN"
        OUT_OF_REACH_FROM_ADDITIONAL_HIGH_WAYPOINT:
            return "OUT_OF_REACH_FROM_ADDITIONAL_HIGH_WAYPOINT"
        THIS_WAYPOINT_OUT_OF_REACH_FROM_PREVIOUS_WAYPOINT:
            return "THIS_WAYPOINT_OUT_OF_REACH_FROM_PREVIOUS_WAYPOINT"
        TRYING_TO_PASS_OVER_WALL_WHILE_DESCENDING:
            return "TRYING_TO_PASS_OVER_WALL_WHILE_DESCENDING"
        TRYING_TO_PASS_UNDER_WALL_WHILE_ASCENDING:
            return "TRYING_TO_PASS_UNDER_WALL_WHILE_ASCENDING"
        NEXT_WAYPOINT_OUT_OF_REACH_FROM_THIS_WAYPOINT:
            return "NEXT_WAYPOINT_OUT_OF_REACH_FROM_THIS_WAYPOINT"
        NO_VALID_VELOCITY_FROM_ORIGIN:
            return "NO_VALID_VELOCITY_FROM_ORIGIN"
        NO_VALID_VELOCITY_FOR_NEXT_STEP:
            return "NO_VALID_VELOCITY_FOR_NEXT_STEP"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Gs.logger.error("Invalid WaypointValidity: %s" % validity)
            return "UNKNOWN"

static func get_description(validity: int) -> String:
    match validity:
        WAYPOINT_VALID:
            return "This waypoint is valid. Valid movement should exist " + \
                    "leading from the previous waypoint to this waypoint " + \
                    "(assuming no intermediate collisions)."
        FAKE:
            return "This waypoint is invalid. It is \"fake\", and should " + \
                    "be replaced with a following waypoint. A fake " + \
                    "waypoint is a point along an end of a surface which " + \
                    "wouldn't actually be efficient to move through, " + \
                    "since movement should instead travel more directly " + \
                    "through the following waypoint."
        TOO_HIGH:
            return "This waypoint is invalid. It is too high"
        OUT_OF_REACH_FROM_ORIGIN:
            return "This waypoint is invalid. It is out of reach for the " + \
                    "origin waypoint."
        OUT_OF_REACH_FROM_ADDITIONAL_HIGH_WAYPOINT:
            return "This waypoint is invalid. It is out of reach from an " + \
                    "additional intermediate high waypoint, which is " + \
                    "being used as the basis for backtracking to consider " + \
                    "a new jump height."
        THIS_WAYPOINT_OUT_OF_REACH_FROM_PREVIOUS_WAYPOINT:
            return "This waypoint is invalid. It is out of reach from the " + \
                    "previous waypoint"
        TRYING_TO_PASS_OVER_WALL_WHILE_DESCENDING:
            return "This waypoint is invalid. It represents passing over " + \
                    "the top of a wall, but the player must already be " + \
                    "descending by the time they reach this waypoint. In " + \
                    "order to pass over the wall, the player would have " + \
                    "to still be ascending."
        TRYING_TO_PASS_UNDER_WALL_WHILE_ASCENDING:
            return "This waypoint is invalid. It represents passing under " + \
                    "a wall, but the player must still be ascending by " + \
                    "the time they reach this waypoint. In order to pass " + \
                    "under the wall, the player would have to already be " + \
                    "descending."
        NEXT_WAYPOINT_OUT_OF_REACH_FROM_THIS_WAYPOINT:
            return "This waypoint is invalid. The next waypoint is out of " + \
                    "reach from this waypoint."
        NO_VALID_VELOCITY_FROM_ORIGIN:
            return "This waypoint is invalid. There is no valid " + \
                    "horizontal velocity that could reach this waypoint " + \
                    "from the origin waypoint."
        NO_VALID_VELOCITY_FOR_NEXT_STEP:
            return "This waypoint is invalid. There is no valid " + \
                    "horizontal velocity that could reach the next " + \
                    "waypoint from this waypoint."
        UNKNOWN:
            return "UNKNOWN"
        _:
            Gs.logger.error("Invalid WaypointValidity: %s" % validity)
            return "UNKNOWN"
