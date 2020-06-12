class_name InspectorSearchType

enum { \
    SURFACE, \
    EDGE, \
    EDGES_GROUP, \
    UNKNOWN, \
}

static func get_type_string(type: int) -> String:
    match type:
        SURFACE:
            return "SURFACE"
        EDGE:
            return "EDGE"
        EDGES_GROUP:
            return "EDGES_GROUP"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Utils.error("Invalid InspectorSearchType: %s" % type)
            return ""
