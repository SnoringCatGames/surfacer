class_name FailedEdgesGroupItemController
extends InspectorItemController

const TYPE := InspectorItemType.FAILED_EDGES_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := true
const PREFIX := "Failed edge calculations"

var origin_surface: Surface
var destination_surface: Surface
var edge_type := EdgeType.UNKNOWN
var edges_results: InterSurfaceEdgesResult

func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        origin_surface: Surface,
        destination_surface: Surface,
        edge_type: int,
        edges_results: InterSurfaceEdgesResult) \
        .(
        TYPE,
        IS_LEAF,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph) -> void:
    self.origin_surface = origin_surface
    self.destination_surface = destination_surface
    self.edge_type = edge_type
    self.edges_results = edges_results
    _post_init()

func to_string() -> String:
    return "%s { failed_count=%s }" % [
        InspectorItemType.get_string(type),
        edges_results.failed_edge_attempts.size(),
    ]

func get_text() -> String:
    return "%s [%s]" % [
        PREFIX,
        edges_results.failed_edge_attempts.size(),
    ]

func get_description() -> String:
    return "These edge calculations failed."

func get_has_children() -> bool:
    return !edges_results.failed_edge_attempts.empty()

func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    assert(search_type == InspectorSearchType.EDGE)
    metadata.were_children_ready_before = are_children_ready
    if !metadata.were_children_ready_before:
        _create_children_if_needed()
    _trigger_find_and_expand_controller_recursive(
            search_type,
            metadata)
    for failed_edge_attempt in edges_results.failed_edge_attempts:
        if Gs.geometry.are_points_equal_with_epsilon(
                        failed_edge_attempt.get_start(),
                        metadata.start,
                        0.01) and \
                Gs.geometry.are_points_equal_with_epsilon(
                        failed_edge_attempt.get_end(),
                        metadata.end,
                        0.01):
            return true
    return false

func _find_and_expand_controller_recursive(
        search_type: int,
        metadata: Dictionary) -> void:
    var is_subtree_found: bool
    var child := tree_item.get_children()
    while child != null:
        is_subtree_found = child.get_metadata(0).find_and_expand_controller(
                search_type,
                metadata)
        if is_subtree_found:
            expand()
            return
        child = child.get_next()
    if !metadata.were_children_ready_before:
        _destroy_children_if_needed()

func _create_children_inner() -> void:
    for failed_edge_attempt in edges_results.failed_edge_attempts:
        FailedEdgeItemController.new(
                tree_item,
                tree,
                graph,
                failed_edge_attempt)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var elements := []
    var element: FailedEdgeAttemptAnnotationElement
    for failed_edge_attempt in edges_results.failed_edge_attempts:
        element = FailedEdgeAttemptAnnotationElement.new(
                failed_edge_attempt,
                Surfacer.ann_defaults \
                        .EDGE_DISCRETE_TRAJECTORY_COLOR_PARAMS,
                Surfacer.ann_defaults.FAILED_EDGE_ATTEMPT_COLOR_PARAMS,
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_LENGTH,
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_GAP,
                AnnotationElementDefaults \
                        .FAILED_EDGE_ATTEMPT_DASH_STROKE_WIDTH,
                false)
        elements.push_back(element)
    return elements
