class_name AnnotationElementType

enum { \
    SURFACE, \
    EDGE, \
    EDGE_STEP, \
    UNKNOWN, \
}

static func get_type_string(type: int) -> String:
    match type:
        SURFACE:
            return "SURFACE"
        EDGE:
            return "EDGE"
        EDGE_STEP:
            return "EDGE_STEP"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Utils.error("Invalid AnnotationElementType: %s" % type)
            return ""
