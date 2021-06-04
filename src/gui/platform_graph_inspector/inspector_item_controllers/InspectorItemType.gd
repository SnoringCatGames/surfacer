class_name InspectorItemType


enum {
    PLATFORM_GRAPH,
    
    EDGES_GROUP,
    EDGES_WITH_INCREASING_JUMP_HEIGHT_GROUP,
    EDGES_WITHOUT_INCREASING_JUMP_HEIGHT_GROUP,
    EDGES_WITH_ONE_STEP_GROUP,
    EDGE_TYPE_IN_EDGES_GROUP,
    
    SURFACES_GROUP,
    FLOORS,
    LEFT_WALLS,
    RIGHT_WALLS,
    CEILINGS,
    ORIGIN_SURFACE,
    DESTINATION_SURFACE,
    EDGE_TYPE_IN_SURFACES_GROUP,
    FAILED_EDGES_GROUP,
    
    PROFILER_GROUP,
    SURFACE_PARSER_GROUP,
    PROFILER_TIMING,
    PROFILER_COUNT,
    
    GLOBAL_COUNTS_GROUP,
    
    DESCRIPTION,
    VALID_EDGE,
    FAILED_EDGE,
    EDGE_CALC_RESULT_METADATA,
    EDGE_CALC_PROFILER_GROUP,
    EDGE_STEP_CALC_RESULT_METADATA,
    
    UNKNOWN,
}


static func get_string(type: int) -> String:
    match type:
        PLATFORM_GRAPH:
            return "PLATFORM_GRAPH"
        
        EDGES_GROUP:
            return "EDGES_GROUP"
        EDGES_WITH_INCREASING_JUMP_HEIGHT_GROUP:
            return "EDGES_WITH_INCREASING_JUMP_HEIGHT_GROUP"
        EDGES_WITHOUT_INCREASING_JUMP_HEIGHT_GROUP:
            return "EDGES_WITHOUT_INCREASING_JUMP_HEIGHT_GROUP"
        EDGES_WITH_ONE_STEP_GROUP:
            return "EDGES_WITH_ONE_STEP_GROUP"
        EDGE_TYPE_IN_EDGES_GROUP:
            return "EDGE_TYPE_IN_EDGES_GROUP"
        
        SURFACES_GROUP:
            return "SURFACES_GROUP"
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
        
        PROFILER_GROUP:
            return "PROFILER_GROUP"
        SURFACE_PARSER_GROUP:
            return "SURFACE_PARSER_GROUP"
        PROFILER_TIMING:
            return "PROFILER_TIMING"
        PROFILER_COUNT:
            return "PROFILER_COUNT"
        
        GLOBAL_COUNTS_GROUP:
            return "GLOBAL_COUNTS_GROUP"
        
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
        EDGE_CALC_PROFILER_GROUP:
            return "EDGE_CALC_PROFILER_GROUP"
        
        UNKNOWN:
            return "UNKNOWN"
        _:
            Gs.logger.error("Invalid InspectorItemType: %s" % type)
            return ""
