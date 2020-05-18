extends InspectorItemController
class_name FailedEdgeItemController

const TYPE := InspectorItemType.FAILED_EDGE
const IS_LEAF := false
const STARTS_COLLAPSED := true

var failed_edge_attempt: FailedEdgeAttempt

func _init( \
        tree_item: TreeItem, \
        tree: Tree, \
        failed_edge_attempt: FailedEdgeAttempt) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        tree_item, \
        tree) -> void:
    self.failed_edge_attempt = failed_edge_attempt
    _post_init()

func to_string() -> String:
    return "%s { %s [%s, %s] }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeType.get_type_string(failed_edge_attempt.edge_type), \
        str(failed_edge_attempt.start), \
        str(failed_edge_attempt.end), \
    ]

func get_text() -> String:
    return "%s [%s, %s]" % [ \
        EdgeCalcResultType.get_result_string( \
                failed_edge_attempt.edge_calc_result_type) if \
        failed_edge_attempt.edge_calc_result_type != \
                EdgeCalcResultType.WAYPOINT_INVALID else \
        WaypointValidity.get_validity_string( \
                failed_edge_attempt.waypoint_validity), \
        str(failed_edge_attempt.start), \
        str(failed_edge_attempt.end), \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> InspectorItemController:
    assert(search_type == InspectorSearchType.EDGE)
    if Geometry.are_points_equal_with_epsilon( \
                    failed_edge_attempt.start, \
                    metadata.start, \
                    0.01) and \
            Geometry.are_points_equal_with_epsilon( \
                    failed_edge_attempt.end, \
                    metadata.end, \
                    0.01):
        expand()
        select()
        return self
    return null

func _create_children_inner() -> void:
    # FIXME: ----------------------------
    pass

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func _draw_annotations() -> void:
    # FIXME: -----------------
    pass
