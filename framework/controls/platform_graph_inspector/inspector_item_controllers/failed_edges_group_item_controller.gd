extends InspectorItemController
class_name FailedEdgesGroupItemController

const TYPE := InspectorItemType.FAILED_EDGES_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := true
const PREFIX := "Failed edge calculations"

var origin_surface: Surface
var destination_surface: Surface
var edge_type := EdgeType.UNKNOWN
# Array<FailedEdgeAttempt>
var failed_edges: Array

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        origin_surface: Surface, \
        destination_surface: Surface, \
        edge_type: int, \
        failed_edges: Array) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.origin_surface = origin_surface
    self.destination_surface = destination_surface
    self.edge_type = edge_type
    self.failed_edges = failed_edges
    _post_init()

func to_string() -> String:
    return "%s { failed_edge_count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        failed_edges.size(), \
    ]

func get_text() -> String:
    return "%s [%s]" % [ \
        PREFIX, \
        failed_edges.size(), \
    ]

func get_has_children() -> bool:
    return failed_edges.size() > 0

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    assert(search_type == InspectorSearchType.EDGE)
    metadata.were_children_ready_before = are_children_ready
    if !metadata.were_children_ready_before:
        _create_children_if_needed()
    call_deferred( \
            "find_and_expand_controller_recursive", \
            search_type, \
            metadata)
    return true

func find_and_expand_controller_recursive( \
        search_type: int, \
        metadata: Dictionary) -> void:
    var is_subtree_found: bool
    var child := tree_item.get_children()
    while child != null:
        is_subtree_found = child.get_metadata(0).find_and_expand_controller( \
                search_type, \
                metadata)
        if is_subtree_found:
            expand()
            return
        child = child.get_next()
    if !metadata.were_children_ready_before:
        _destroy_children_if_needed()

func _create_children_inner() -> void:
    for failed_edge_attempt in failed_edges:
        FailedEdgeItemController.new( \
                tree_item, \
                tree, \
                graph, \
                failed_edge_attempt)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var elements := []
    var element: FailedEdgeAttemptAnnotationElement
    for failed_edge_attempt in failed_edges:
        element = FailedEdgeAttemptAnnotationElement.new( \
                failed_edge_attempt, \
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_COLOR_PARAMS, \
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_RADIUS, \
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_LENGTH, \
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_GAP, \
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_STROKE_WIDTH, \
                false)
        elements.push_back(element)
    return elements
