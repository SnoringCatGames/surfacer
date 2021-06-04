class_name LegendItemType


enum {
    SURFACE,
    ORIGIN_SURFACE,
    DESTINATION_SURFACE,
    HYPOTHETICAL_EDGE_TRAJECTORY,
    FAILED_EDGE_TRAJECTORY,
    DISCRETE_EDGE_TRAJECTORY,
    CONTINUOUS_EDGE_TRAJECTORY,
    ORIGIN,
    DESTINATION,
    INSTRUCTION_START,
    INSTRUCTION_END,
    FALL_RANGE_WITH_JUMP_DISTANCE,
    FALL_RANGE_WITHOUT_JUMP_DISTANCE,
    UNKNOWN,
}


static func get_string(type: int) -> String:
    match type:
        SURFACE:
            return "SURFACE"
        ORIGIN_SURFACE:
            return "ORIGIN_SURFACE"
        DESTINATION_SURFACE:
            return "DESTINATION_SURFACE"
        HYPOTHETICAL_EDGE_TRAJECTORY:
            return "HYPOTHETICAL_EDGE_TRAJECTORY"
        FAILED_EDGE_TRAJECTORY:
            return "FAILED_EDGE_TRAJECTORY"
        DISCRETE_EDGE_TRAJECTORY:
            return "DISCRETE_EDGE_TRAJECTORY"
        CONTINUOUS_EDGE_TRAJECTORY:
            return "CONTINUOUS_EDGE_TRAJECTORY"
        ORIGIN:
            return "ORIGIN"
        DESTINATION:
            return "DESTINATION"
        INSTRUCTION_START:
            return "INSTRUCTION_START"
        INSTRUCTION_END:
            return "INSTRUCTION_END"
        FALL_RANGE_WITH_JUMP_DISTANCE:
            return "FALL_RANGE_WITH_JUMP_DISTANCE"
        FALL_RANGE_WITHOUT_JUMP_DISTANCE:
            return "FALL_RANGE_WITHOUT_JUMP_DISTANCE"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Gs.logger.error("Invalid LegendItemType: %s" % type)
            return ""
