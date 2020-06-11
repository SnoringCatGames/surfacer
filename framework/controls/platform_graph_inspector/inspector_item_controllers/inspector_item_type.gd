class_name InspectorItemType

enum { \
    PLATFORM_GRAPH, \
    EDGES_TOP_LEVEL_GROUP, \
    SURFACES_TOP_LEVEL_GROUP, \
    ANALYTICS_TOP_LEVEL_GROUP, \
    GLOBAL_COUNTS_TOP_LEVEL_GROUP, \
    EDGE_TYPE_IN_EDGES_GROUP, \
    FLOORS, \
    LEFT_WALLS, \
    RIGHT_WALLS, \
    CEILINGS, \
    ORIGIN_SURFACE, \
    DESTINATION_SURFACE, \
    EDGE_TYPE_IN_SURFACES_GROUP, \
    FAILED_EDGES_GROUP, \
    DESCRIPTION, \
    VALID_EDGE, \
    FAILED_EDGE, \
    EDGE_CALC_RESULT_METADATA, \
    EDGE_STEP_CALC_RESULT_METADATA, \
    UNKNOWN, \
}

static func get_type_string(type: int) -> String:
    match type:
        PLATFORM_GRAPH:
            return "PLATFORM_GRAPH"
        EDGES_TOP_LEVEL_GROUP:
            return "EDGES_TOP_LEVEL_GROUP"
        SURFACES_TOP_LEVEL_GROUP:
            return "SURFACES_TOP_LEVEL_GROUP"
        ANALYTICS_TOP_LEVEL_GROUP:
            return "ANALYTICS_TOP_LEVEL_GROUP"
        GLOBAL_COUNTS_TOP_LEVEL_GROUP:
            return "GLOBAL_COUNTS_TOP_LEVEL_GROUP"
        EDGE_TYPE_IN_EDGES_GROUP:
            return "EDGE_TYPE_IN_EDGES_GROUP"
        FLOORS:
            return "FLOORS"
        LEFT_WALLS:
            return "LEFT_WALLS"
        RIGHT_WALLS:
            return "RIGHT_WALLS"
        CEILINGS:
            return "CEILINGS"
        ORIGIN_SURFACE:
            return "ORIGIN_SURFACE"
        DESTINATION_SURFACE:
            return "DESTINATION_SURFACE"
        EDGE_TYPE_IN_SURFACES_GROUP:
            return "EDGE_TYPE_IN_SURFACES_GROUP"
        FAILED_EDGES_GROUP:
            return "FAILED_EDGES_GROUP"
        DESCRIPTION:
            return "DESCRIPTION"
        VALID_EDGE:
            return "VALID_EDGE"
        FAILED_EDGE:
            return "FAILED_EDGE"
        EDGE_CALC_RESULT_METADATA:
            return "EDGE_CALC_RESULT_METADATA"
        EDGE_STEP_CALC_RESULT_METADATA:
            return "EDGE_STEP_CALC_RESULT_METADATA"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Utils.error("Invalid InspectorItemType: %s" % type)
            return ""
