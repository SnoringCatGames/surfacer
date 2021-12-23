class_name InspectorSearchType


enum { \
    ORIGIN_SURFACE,
    DESTINATION_SURFACE,
    EDGE,
    EDGES_GROUP,
    UNKNOWN,
}


static func get_string(type: int) -> String:
    match type:
        ORIGIN_SURFACE:
            return "ORIGIN_SURFACE"
        DESTINATION_SURFACE:
            return "DESTINATION_SURFACE"
        EDGE:
            return "EDGE"
        EDGES_GROUP:
            return "EDGES_GROUP"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Sc.logger.error("Invalid InspectorSearchType: %s" % type)
            return ""
