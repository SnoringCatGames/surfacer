class_name AnnotationElementType

enum {
    SURFACE,
    ORIGIN_SURFACE,
    DESTINATION_SURFACE,
    EDGE,
    FAILED_EDGE_ATTEMPT,
    JUMP_LAND_POSITIONS,
    EDGE_STEP,
    FALL_RANGE_WITH_JUMP_DISTANCE,
    FALL_RANGE_WITHOUT_JUMP_DISTANCE,
    UNKNOWN,
}

static func get_type_string(type: int) -> String:
    match type:
        SURFACE:
            return "SURFACE"
        ORIGIN_SURFACE:
            return "ORIGIN_SURFACE"
        DESTINATION_SURFACE:
            return "DESTINATION_SURFACE"
        EDGE:
            return "EDGE"
        FAILED_EDGE_ATTEMPT:
            return "FAILED_EDGE_ATTEMPT"
        JUMP_LAND_POSITIONS:
            return "JUMP_LAND_POSITIONS"
        EDGE_STEP:
            return "EDGE_STEP"
        FALL_RANGE_WITH_JUMP_DISTANCE:
            return "FALL_RANGE_WITH_JUMP_DISTANCE"
        FALL_RANGE_WITHOUT_JUMP_DISTANCE:
            return "FALL_RANGE_WITHOUT_JUMP_DISTANCE"
        UNKNOWN:
            return "UNKNOWN"
        _:
            ScaffoldUtils.error("Invalid AnnotationElementType: %s" % type)
            return ""
