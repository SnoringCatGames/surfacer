extends InspectorItemController
class_name EdgeTypeInEdgesGroupItemController

const TYPE := InspectorItemType.EDGE_TYPE_IN_EDGES_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := true

var edge_type := EdgeType.UNKNOWN
var valid_edge_count := 0

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        edge_type: int) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.edge_type = edge_type
    self.valid_edge_count = graph.counts[EdgeType.get_type_string(edge_type)]
    _post_init()

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

func get_has_children() -> bool:
    return valid_edge_count > 0

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> InspectorItemController:
    var result: InspectorItemController
    var child := tree_item.get_children()
    while child != null:
        result = child.get_metadata(0).find_and_expand_controller( \
                search_type, \
                metadata)
        if result != null:
            return result
        child = child.get_next()
    return null

func _create_children_inner() -> void:
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
                        graph, \
                        edge)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func _draw_annotations() -> void:
    # FIXME: -----------------
    pass
