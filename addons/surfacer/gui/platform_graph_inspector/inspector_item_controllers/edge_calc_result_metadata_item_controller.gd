extends InspectorItemController
class_name EdgeCalcResultMetadataItemController

const TYPE := InspectorItemType.EDGE_CALC_RESULT_METADATA
const IS_LEAF := false
const STARTS_COLLAPSED := false
const PREFIX := "Calculation"

var edge_attempt: EdgeAttempt
var edge_result_metadata: EdgeCalcResultMetadata

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        edge_attempt: EdgeAttempt, \
        edge_result_metadata: EdgeCalcResultMetadata) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    assert(edge_attempt != null)
    assert(edge_result_metadata != null)
    self.edge_attempt = edge_attempt
    self.edge_result_metadata = edge_result_metadata
    _post_init()

func to_string() -> String:
    return ("%s { " + \
            "edge_calc_result_type=%s, " + \
            "waypoint_validity=%s, " + \
            "step_count=%s " + \
            "}") % [ \
        InspectorItemType.get_type_string(type), \
        EdgeCalcResultType.get_type_string( \
                edge_result_metadata.edge_calc_result_type), \
        WaypointValidity.get_type_string( \
                edge_result_metadata.waypoint_validity), \
        edge_result_metadata.total_step_count, \
    ]

func get_text() -> String:
    return "%s (%s) [%s]" % [ \
        PREFIX, \
        EdgeCalcResultType.get_type_string( \
                edge_result_metadata.edge_calc_result_type) if \
        edge_result_metadata.edge_calc_result_type != \
                EdgeCalcResultType.WAYPOINT_INVALID else \
        WaypointValidity.get_type_string( \
                edge_result_metadata.waypoint_validity), \
        edge_result_metadata.total_step_count, \
    ]

func get_description() -> String:
    return "Calculation details for this edge. " + \
            (EdgeCalcResultType.get_description_string( \
                    edge_result_metadata.edge_calc_result_type) if \
            edge_result_metadata.edge_calc_result_type != \
                    EdgeCalcResultType.WAYPOINT_INVALID else \
            WaypointValidity.get_description_string( \
                    edge_result_metadata.waypoint_validity))

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Utils.error( \
            "find_and_expand_controller should not be called for " + \
            "EDGE_CALC_RESULT_METADATA.")
    return false

func get_has_children() -> bool:
    return !edge_result_metadata.failed_before_creating_steps

func _create_children_inner() -> void:
    for step_result_metadata in edge_result_metadata.children_step_attempts:
        EdgeStepCalcResultMetadataItemController.new( \
                tree_item, \
                tree, \
                graph, \
                edge_attempt, \
                step_result_metadata, \
                EdgeStepCalcResultMetadataItemControllerFactory)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var elements := []
    var element: AnnotationElement
    if !edge_result_metadata.failed_before_creating_steps:
        for step_result_metadata in \
                edge_result_metadata.children_step_attempts:
            element = EdgeStepAnnotationElement.new( \
                    step_result_metadata, \
                    true)
            elements.push_back(element)
    elif edge_attempt is FailedEdgeAttempt:
        element = FailedEdgeAttemptAnnotationElement.new( \
                edge_attempt, \
                AnnotationElementDefaults \
                        .EDGE_DISCRETE_TRAJECTORY_COLOR_PARAMS, \
                AnnotationElementDefaults.INVALID_EDGE_COLOR_PARAMS, \
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_LENGTH, \
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_GAP, \
                AnnotationElementDefaults \
                        .FAILED_EDGE_ATTEMPT_DASH_STROKE_WIDTH, \
                false)
        elements.push_back(element)
    else:
        assert(edge_attempt is Edge and \
                !edge_attempt.includes_air_trajectory)
    return elements
