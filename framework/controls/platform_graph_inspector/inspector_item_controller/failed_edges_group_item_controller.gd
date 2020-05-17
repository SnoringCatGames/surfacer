extends InspectorItemController
class_name FailedEdgesGroupItemController

const TYPE := InspectorItemType.FAILED_EDGES_GROUP
const STARTS_COLLAPSED := true

var origin_surface: Surface
var destination_surface: Surface
var edge_type := EdgeType.UNKNOWN
# Array<FailedEdgeAttempt>
var failed_edges: Array

func _init( \
        tree_item: TreeItem, \
        tree: Tree, \
        origin_surface: Surface, \
        destination_surface: Surface, \
        edge_type: int, \
        failed_edges: Array) \
        .( \
        TYPE, \
        STARTS_COLLAPSED, \
        tree_item, \
        tree) -> void:
    self.origin_surface = origin_surface
    self.destination_surface = destination_surface
    self.edge_type = edge_type
    self.failed_edges = failed_edges
    _update_text()

func to_string() -> String:
    return "%s { edge_type=%s, failed_edge_count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeType.get_type_string(edge_type), \
        failed_edges.size(), \
    ]

func get_text() -> String:
    return "%ss [%s]" % [ \
        EdgeType.get_type_string(edge_type), \
        failed_edges.size(), \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> InspectorItemController:
    assert(search_type == InspectorSearchType.EDGE)
    
    var were_children_ready_before := are_children_ready
    if !are_children_ready:
        _create_children()
        are_children_ready = true
    
    var result: InspectorItemController
    for child in tree_item.get_children():
        result = child.get_metadata(0).find_and_expand_controller( \
                search_type, \
                metadata)
        if result != null:
            expand()
            return result
    
    if !were_children_ready_before:
        _destroy_children()
        are_children_ready = false
    
    return null

func _create_children() -> void:
    for failed_edge_attempt in failed_edges:
        FailedEdgeItemController.new( \
                tree_item, \
                tree, \
                failed_edge_attempt)

func _destroy_children() -> void:
    for child in tree_item.get_children():
        child.get_metadata(0).destroy()

func _draw_annotations() -> void:
    # FIXME: -----------------
    pass
