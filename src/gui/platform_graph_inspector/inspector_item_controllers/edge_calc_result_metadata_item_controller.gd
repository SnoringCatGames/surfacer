class_name EdgeCalcResultMetadataItemController
extends InspectorItemController


const TYPE := InspectorItemType.EDGE_CALC_RESULT_METADATA
const IS_LEAF := false
const STARTS_COLLAPSED := false
const PREFIX := "Calculation"

var edge_attempt: EdgeAttempt
var edge_result_metadata: EdgeCalcResultMetadata


func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        edge_attempt: EdgeAttempt,
        edge_result_metadata: EdgeCalcResultMetadata) \
        .(
        TYPE,
        IS_LEAF,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph) -> void:
    assert(edge_attempt != null)
    assert(edge_result_metadata != null)
    self.edge_attempt = edge_attempt
    self.edge_result_metadata = edge_result_metadata
    _post_init()


func to_string() -> String:
    return ("%s { " +
            "edge_calc_result_type=%s, " +
            "waypoint_validity=%s, " +
            "step_count=%s " +
            "}") % [
        InspectorItemType.get_string(type),
        EdgeCalcResultType.get_string(
                edge_result_metadata.edge_calc_result_type),
        WaypointValidity.get_string(
                edge_result_metadata.waypoint_validity),
        edge_result_metadata.total_step_count,
    ]


func get_text() -> String:
    return "%s (%s) [%s]" % [
        PREFIX,
        EdgeCalcResultType.get_string(
                edge_result_metadata.edge_calc_result_type) if \
        edge_result_metadata.edge_calc_result_type != \
                EdgeCalcResultType.WAYPOINT_INVALID else \
        WaypointValidity.get_string(
                edge_result_metadata.waypoint_validity),
        edge_result_metadata.total_step_count,
    ]


func get_description() -> String:
    return "Calculation details for this edge. " + \
            (EdgeCalcResultType.get_description(
                    edge_result_metadata.edge_calc_result_type) if \
            edge_result_metadata.edge_calc_result_type != \
                    EdgeCalcResultType.WAYPOINT_INVALID else \
            WaypointValidity.get_description(
                    edge_result_metadata.waypoint_validity))


func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    Sc.logger.error(
            "find_and_expand_controller should not be called for " +
            "EDGE_CALC_RESULT_METADATA.")
    return false


func get_has_children() -> bool:
    return !edge_result_metadata.failed_before_creating_steps


func _create_children_inner() -> void:
    for step_result_metadata in edge_result_metadata.children_step_attempts:
        EdgeStepCalcResultMetadataItemController.new(
                tree_item,
                tree,
                graph,
                edge_attempt,
                step_result_metadata,
                EdgeStepCalcResultMetadataItemControllerFactory)


func _destroy_children_inner() -> void:
    # Do nothing.
    pass


func get_annotation_elements() -> Array:
    var elements := []
    if !edge_result_metadata.failed_before_creating_steps:
        for step_result_metadata in \
                edge_result_metadata.children_step_attempts:
            var element := EdgeStepAnnotationElement.new(
                    step_result_metadata,
                    true)
            elements.push_back(element)
    elif edge_attempt is FailedEdgeAttempt:
        var element := FailedEdgeAttemptAnnotationElement.new(
                edge_attempt,
                Sc.palette.get_color("edge_discrete_trajectory_color"),
                Sc.palette.get_color("invalid_edge_color"),
                Sc.annotators.params.failed_edge_attempt_dash_length,
                Sc.annotators.params.failed_edge_attempt_dash_gap,
                Sc.annotators.params \
                        .failed_edge_attempt_dash_stroke_width,
                false)
        elements.push_back(element)
    else:
        assert(edge_attempt is Edge)
    return elements
