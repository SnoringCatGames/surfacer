extends InspectorItemController
class_name EdgesTopLevelGroupItemController

const TYPE := InspectorItemType.EDGES_TOP_LEVEL_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := true
const PREFIX := "Edges"

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    _post_init()

func get_text() -> String:
    return "%s [%s]" % [ \
        PREFIX, \
        graph.counts.total_edges, \
    ]

func to_string() -> String:
    return "%s { count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        graph.counts.total_edges, \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Utils.error("find_and_expand_controller should not be called for EDGES_TOP_LEVEL_GROUP.")
    return false

func _create_children_inner() -> void:
    for edge_type in EdgeType.values():
        if InspectorItemController.EDGE_TYPES_TO_SKIP.find(edge_type) >= 0:
            continue
        EdgeTypeInEdgesGroupItemController.new( \
                tree_item, \
                tree, \
                graph, \
                edge_type)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    return get_annotation_elements_from_graph(graph)

static func get_annotation_elements_from_graph(graph: PlatformGraph) -> Array:
    var elements := []
    var element: EdgeAnnotationElement
    var edge: Edge
    for origin_surface in graph.surfaces_set:
        for origin_node in graph.surfaces_to_outbound_nodes[origin_surface]:
            for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
                edge = graph.nodes_to_nodes_to_edges[origin_node][destination_node]
                element = EdgeAnnotationElement.new( \
                        edge, \
                        true, \
                        false, \
                        false)
                elements.push_back(element)
    return elements
