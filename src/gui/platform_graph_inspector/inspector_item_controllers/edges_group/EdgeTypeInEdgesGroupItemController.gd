class_name EdgeTypeInEdgesGroupItemController
extends InspectorItemController

const TYPE := InspectorItemType.EDGE_TYPE_IN_EDGES_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := true

var edge_calc_result_type := EdgeCalcResultType.UNKNOWN
var edge_type := EdgeType.UNKNOWN
# Array<Edge>
var edges: Array

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        edge_calc_result_type: int, \
        edge_type: int, \
        edges: Array) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.edge_calc_result_type = edge_calc_result_type
    self.edge_type = edge_type
    self.edges = edges
    _post_init()

func to_string() -> String:
    return ("%s { " + \
            "edge_calc_result_type=%s, " + \
            "edge_type=%s, " + \
            "valid_edge_count=%s " + \
            "}") % [ \
        InspectorItemType.get_type_string(type), \
        EdgeCalcResultType.get_type_string(edge_calc_result_type),
        EdgeType.get_type_string(edge_type), \
        edges.size(), \
    ]

func get_text() -> String:
    return "%ss [%s]" % [ \
        EdgeType.get_type_string(edge_type), \
        edges.size(), \
    ]

func get_description() -> String:
    return EdgeType.get_description_string(edge_type)

func get_has_children() -> bool:
    return !edges.empty()

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Gs.utils.error("find_and_expand_controller should not be called for " + \
            "EDGE_TYPE_IN_EDGES_GROUP.")
    return false

func _create_children_inner() -> void:
    for edge in edges:
        ValidEdgeItemController.new( \
                tree_item, \
                tree, \
                graph, \
                edge)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var elements := []
    var element: EdgeAnnotationElement
    for edge in edges:
        element = EdgeAnnotationElement.new( \
                edge, \
                true, \
                false, \
                true, \
                false)
        elements.push_back(element)
    return elements

static func get_annotation_elements_from_graph_and_type( \
        graph: PlatformGraph, \
        edge_type: int) -> Array:
    var elements := []
    var element: EdgeAnnotationElement
    for origin_surface in graph.surfaces_set:
        for origin_node in graph.surfaces_to_outbound_nodes[origin_surface]:
            for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
                for edge in graph.nodes_to_nodes_to_edges[origin_node][ \
                        destination_node]:
                    if edge.edge_type == edge_type:
                        element = EdgeAnnotationElement.new( \
                                edge, \
                                true, \
                                false, \
                                true, \
                                false)
                        elements.push_back(element)
    return elements
