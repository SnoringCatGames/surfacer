class_name InspectorSearchType

enum { \
    SURFACE, \
    EDGE, \
    UNKNOWN, \
}

static func get_type_string(type: int) -> String:
    match type:
        SURFACE:
            return "SURFACE"
        EDGE:
            return "EDGE"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Utils.error("Invalid InspectorSearchType: %s" % type)
            return ""
