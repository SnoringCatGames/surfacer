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

func get_description() -> String:
    return EdgeType.get_description_string(edge_type)

func get_has_children() -> bool:
    return valid_edge_count > 0

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Utils.error("find_and_expand_controller should not be called for EDGE_TYPE_IN_EDGES_GROUP.")
    return false

func _create_children_inner() -> void:
    var edge: Edge
    for origin_surface in graph.surfaces_set:
        for origin_node in graph.surfaces_to_outbound_nodes[origin_surface]:
            for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
                edge = graph.nodes_to_nodes_to_edges[origin_node][destination_node]
                if edge.type == edge_type and \
                        InspectorItemController.EDGE_TYPES_TO_SKIP.find(edge.type) < 0:
                    ValidEdgeItemController.new( \
                            tree_item, \
                            tree, \
                            graph, \
                            edge)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    return get_annotation_elements_from_graph_and_type( \
            graph, \
            edge_type)

static func get_annotation_elements_from_graph_and_type( \
        graph: PlatformGraph, \
        edge_type: int) -> Array:
    var elements := []
    var element: EdgeAnnotationElement
    var edge: Edge
    for origin_surface in graph.surfaces_set:
        for origin_node in graph.surfaces_to_outbound_nodes[origin_surface]:
            for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
                edge = graph.nodes_to_nodes_to_edges[origin_node][destination_node]
                if edge.type == edge_type:
                    element = EdgeAnnotationElement.new( \
                            edge, \
                            true, \
                            false, \
                            false)
                    elements.push_back(element)
    return elements
