class_name LegendItemType

enum { \
    SURFACE, \
    ORIGIN_SURFACE, \
    DESTINATION_SURFACE, \
    JUMP_LAND_POSITION_PAIR, \
    FAILED_EDGE, \
    VALID_EDGE_TRAJECTORY, \
    EDGE_START, \
    EDGE_END, \
    JUMP_INSTRUCTION_START, \
    JUMP_INSTRUCTION_END, \
    LEFT_INSTRUCTION_START, \
    LEFT_INSTRUCTION_END, \
    RIGHT_INSTRUCTION_START, \
    RIGHT_INSTRUCTION_END, \
    UNKNOWN, \
}

static func get_type_string(type: int) -> String:
    match type:
        SURFACE:
            return "SURFACE"
        ORIGIN_SURFACE:
            return "ORIGIN_SURFACE"
        DESTINATION_SURFACE:
            return "DESTINATION_SURFACE"
        JUMP_LAND_POSITION_PAIR:
            return "JUMP_LAND_POSITION_PAIR"
        FAILED_EDGE:
            return "FAILED_EDGE"
        VALID_EDGE_TRAJECTORY:
            return "VALID_EDGE_TRAJECTORY"
        EDGE_START:
            return "EDGE_START"
        EDGE_END:
            return "EDGE_END"
        JUMP_INSTRUCTION_START:
            return "JUMP_INSTRUCTION_START"
        JUMP_INSTRUCTION_END:
            return "JUMP_INSTRUCTION_END"
        LEFT_INSTRUCTION_START:
            return "LEFT_INSTRUCTION_START"
        LEFT_INSTRUCTION_END:
            return "LEFT_INSTRUCTION_END"
        RIGHT_INSTRUCTION_START:
            return "RIGHT_INSTRUCTION_START"
        RIGHT_INSTRUCTION_END:
            return "RIGHT_INSTRUCTION_END"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Utils.error("Invalid LegendItemType: %s" % type)
            return ""
