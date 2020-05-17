extends InspectorItemController
class_name EdgeTypeInEdgesGroupItemController

const TYPE := InspectorItemType.EDGE_TYPE_IN_EDGES_GROUP
const STARTS_COLLAPSED := true

var graph: PlatformGraph
var edge_type := EdgeType.UNKNOWN
var valid_edge_count := 0

func _init( \
        tree_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        edge_type: int) \
        .( \
        TYPE, \
        STARTS_COLLAPSED, \
        tree_item, \
        tree) -> void:
    self.graph = graph
    self.edge_type = edge_type
    self.valid_edge_count = graph.counts[EdgeType.get_type_string(edge_type)]
    _update_text()

func to_string() -> String:
    return "%s { edge_type=%s, valid_edge_count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeType.get_type_string(edge_type), \
        valid_edge_count, \
    ]

func get_text() -> String:
    return "%ss [%s]" % [ \
        EdgeType.get_type_string(edge_type), \
        valid_edge_count, \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> InspectorItemController:
    var result: InspectorItemController
    for child in tree_item.get_children():
        result = child.get_metadata(0).find_and_expand_controller( \
                search_type, \
                metadata)
        if result != null:
            return result
    return null

func _create_children() -> void:
    var edge: Edge
    for origin_surface in graph.surfaces_set:
        for origin_node in graph.surfaces_to_outbound_nodes[origin_surface]:
            for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
                edge = graph.nodes_to_nodes_to_edges[origin_node][destination_node]
                if InspectorItemController.EDGE_TYPES_TO_SKIP.find(edge.type) >= 0:
                    continue
                ValidEdgeItemController.new( \
                        tree_item, \
                        tree, \
                        edge)

func _destroy_children() -> void:
    for child in tree_item.get_children():
        child.get_metadata(0).destroy()

func _draw_annotations() -> void:
    # FIXME: -----------------
    pass
