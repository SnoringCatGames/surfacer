class_name AnnotationElementType

enum { \
    SURFACE, \
    EDGE, \
    FAILED_EDGE_ATTEMPT, \
    JUMP_LAND_POSITIONS, \
    EDGE_STEP, \
    UNKNOWN, \
}

static func get_type_string(type: int) -> String:
    match type:
        SURFACE:
            return "SURFACE"
        EDGE:
            return "EDGE"
        FAILED_EDGE_ATTEMPT:
            return "FAILED_EDGE_ATTEMPT"
        JUMP_LAND_POSITIONS:
            return "JUMP_LAND_POSITIONS"
        EDGE_STEP:
            return "EDGE_STEP"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Utils.error("Invalid AnnotationElementType: %s" % type)
            return ""
