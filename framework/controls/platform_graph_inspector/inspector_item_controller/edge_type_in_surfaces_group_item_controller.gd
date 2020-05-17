extends InspectorItemController
class_name EdgeTypeInSurfacesGroupItemController

const TYPE := InspectorItemType.EDGE_TYPE_IN_SURFACES_GROUP
const STARTS_COLLAPSED := true

var origin_surface: Surface
var destination_surface: Surface
var edge_type := EdgeType.UNKNOWN
# Array<Edge>
var valid_edges: Array
# Array<FailedEdgeAttempt>
var failed_edges: Array

var failed_edges_controller: FailedEdgesGroupItemController

func _init( \
        tree_item: TreeItem, \
        tree: Tree, \
        origin_surface: Surface, \
        destination_surface: Surface, \
        edge_type: int, \
        valid_edges: Array, \
        failed_edges: Array) \
        .( \
        TYPE, \
        STARTS_COLLAPSED, \
        tree_item, \
        tree) -> void:
    self.origin_surface = origin_surface
    self.destination_surface = destination_surface
    self.edge_type = edge_type
    self.valid_edges = valid_edges
    self.failed_edges = failed_edges
    _update_text()

func to_string() -> String:
    return "%s { edge_type=%s, valid_edge_count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeType.get_type_string(edge_type), \
        valid_edges.size(), \
    ]

func get_text() -> String:
    return "%ss [%s]" % [ \
        EdgeType.get_type_string(edge_type), \
        valid_edges.size(), \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> InspectorItemController:
    assert(search_type == InspectorSearchType.EDGE)
    
    if metadata.edge_type != edge_type:
        return null
    
    expand()
    
    var result: InspectorItemController
    for child in tree_item.get_children():
        result = child.get_metadata(0).find_and_expand_controller( \
                search_type, \
                metadata)
        if result != null:
            return result
    
    select()
    
    return null

func _create_children() -> void:
    for edge in valid_edges:
        ValidEdgeItemController.new( \
                tree_item, \
                tree, \
                edge)
    
    failed_edges_controller = FailedEdgesGroupItemController.new( \
            tree_item, \
            tree, \
            origin_surface, \
            destination_surface, \
            edge_type, \
            failed_edges)

func _destroy_children() -> void:
    for child in tree_item.get_children():
        child.get_metadata(0).destroy()
    failed_edges_controller = null

func _draw_annotations() -> void:
    # FIXME: -----------------
    pass
