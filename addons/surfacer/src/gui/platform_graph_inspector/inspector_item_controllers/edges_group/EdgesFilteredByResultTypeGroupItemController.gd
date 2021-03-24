class_name EdgesFilteredByResultTypeGroupItemController
extends InspectorItemController

const IS_LEAF := false
const STARTS_COLLAPSED := true

var edge_calc_result_type := EdgeCalcResultType.UNKNOWN
var text: String
# Dictionary<EdgeType, Array<Edge>>
var edge_types_to_filtered_edges: Dictionary
var filtered_edge_count: int

func _init( \
        type: int, \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        edge_calc_result_type: int, \
        text) \
        .( \
        type, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.edge_calc_result_type = edge_calc_result_type
    self.text = text
    _init_edge_types_to_filtered_edges( \
            graph, \
            edge_calc_result_type)
    _post_init()

func _init_edge_types_to_filtered_edges( \
        graph: PlatformGraph, \
        edge_calc_result_type: int) -> void:
    var filtered_edges := []
    for origin_surface in graph.surfaces_set:
        for origin_node in graph.surfaces_to_outbound_nodes[origin_surface]:
            for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
                for edge in graph.nodes_to_nodes_to_edges[origin_node][ \
                        destination_node]:
                    if edge.edge_calc_result_type == edge_calc_result_type:
                        filtered_edges.push_back(edge)
    
    self.filtered_edge_count = filtered_edges.size()
    self.edge_types_to_filtered_edges = {}
    
    for edge in filtered_edges:
        if !InspectorItemController.EDGE_TYPES_TO_SKIP.find( \
                edge.edge_type) < 0:
            continue
        if !edge_types_to_filtered_edges.has(edge.edge_type):
            edge_types_to_filtered_edges[edge.edge_type] = []
        edge_types_to_filtered_edges[edge.edge_type].push_back(edge)

func get_text() -> String:
    return "[%s] %s" % [ \
        filtered_edge_count, \
        text, \
    ]

func to_string() -> String:
    return "%s { count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        filtered_edge_count, \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Gs.utils.error( \
            "find_and_expand_controller should not be called for " + \
            "%s." % InspectorItemType.get_type_string(type))
    return false

func _create_children_inner() -> void:
    for edge_type in edge_types_to_filtered_edges:
        EdgeTypeInEdgesGroupItemController.new( \
                tree_item, \
                tree, \
                graph, \
                edge_calc_result_type, \
                edge_type, \
                edge_types_to_filtered_edges[edge_type])

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var elements := []
    var element: EdgeAnnotationElement
    for edge_type in edge_types_to_filtered_edges:
        for edge in edge_types_to_filtered_edges[edge_type]:
            element = EdgeAnnotationElement.new( \
                    edge, \
                    true, \
                    false, \
                    true, \
                    false)
            elements.push_back(element)
    return elements
