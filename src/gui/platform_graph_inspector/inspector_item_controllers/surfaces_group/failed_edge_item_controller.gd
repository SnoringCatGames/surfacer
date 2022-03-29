class_name FailedEdgeItemController
extends EdgeAttemptItemController


const TYPE := InspectorItemType.FAILED_EDGE

const BROAD_PHASE_DESCRIPTION := (
    "These calculations failed during the \"broad phase\", which means " +
    "that expensive edge trajectories hadn't yet been calculated.")
const NARROW_PHASE_DESCRIPTION := (
    "These calculations failed during the \"narrow phase\", which means " +
    "during expensive edge trajectory calculations.")

var failed_edge_attempt: FailedEdgeAttempt


func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        failed_edge_attempt: FailedEdgeAttempt) \
        .(
        TYPE,
        parent_item,
        tree,
        graph,
        failed_edge_attempt) -> void:
    assert(failed_edge_attempt != null)
    self.failed_edge_attempt = failed_edge_attempt
    _post_init()


func to_string() -> String:
    return "%s { %s; [%s] %s; [%s, %s] }" % [
        InspectorItemType.get_string(type),
        EdgeType.get_string(failed_edge_attempt.edge_type),
        "BP" if \
        failed_edge_attempt.is_broad_phase_failure else \
        "NP",
        EdgeCalcResultType.get_string(
                failed_edge_attempt.edge_calc_result_type) if \
        failed_edge_attempt.edge_calc_result_type != \
                EdgeCalcResultType.WAYPOINT_INVALID else \
        WaypointValidity.get_string(
                failed_edge_attempt.waypoint_validity),
        str(failed_edge_attempt.get_start()),
        str(failed_edge_attempt.get_end()),
    ]


func get_text() -> String:
    return "[%s] %s [%s, %s]" % [
        "BP" if \
        failed_edge_attempt.is_broad_phase_failure else \
        "NP",
        EdgeCalcResultType.get_string(
                failed_edge_attempt.edge_calc_result_type) if \
        failed_edge_attempt.edge_calc_result_type != \
                EdgeCalcResultType.WAYPOINT_INVALID else \
        WaypointValidity.get_string(
                failed_edge_attempt.waypoint_validity),
        str(failed_edge_attempt.get_start()),
        str(failed_edge_attempt.get_end()),
    ]


func get_description() -> String:
    return ("This jump/land pair was calculated as possibly corresponding " +
                "to a valid edge, but later calculations failed. %s") % \
                (BROAD_PHASE_DESCRIPTION if \
                failed_edge_attempt.is_broad_phase_failure else \
                NARROW_PHASE_DESCRIPTION)


func get_has_children() -> bool:
    return !failed_edge_attempt.is_broad_phase_failure


func get_annotation_elements() -> Array:
    var element := FailedEdgeAttemptAnnotationElement.new(
            failed_edge_attempt,
            Sc.palette.get_color("edge_discrete_trajectory_color"),
            Sc.palette.get_color("failed_edge_attempt_color"),
            Sc.annotators.params.failed_edge_attempt_dash_length,
            Sc.annotators.params.failed_edge_attempt_dash_gap,
            Sc.annotators.params.failed_edge_attempt_dash_stroke_width,
            false)
    return [element]
