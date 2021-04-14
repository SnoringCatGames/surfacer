class_name EdgesGroupItemController
extends InspectorItemController

const TYPE := InspectorItemType.EDGES_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := false
const PREFIX := "Edges"

# Dictionary<Surface, Dictionary<Surface, Dictionary<int,
#         Array<InterSurfaceEdgesResult>>>>
var surfaces_to_surfaces_to_edge_types_to_edges_results := {}

func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        surfaces_to_surfaces_to_edge_types_to_edges_results: Dictionary) \
        .(
        TYPE,
        IS_LEAF,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph) -> void:
    self.surfaces_to_surfaces_to_edge_types_to_edges_results = \
            surfaces_to_surfaces_to_edge_types_to_edges_results
    _post_init()

func get_text() -> String:
    return "%s [%s]" % [
        PREFIX,
        graph.counts.total_edges,
    ]

func get_description() -> String:
    return ("An edge represents movement between two surface positions. " + \
            "There are %s total edges in this platform graph for the %s " + \
            "player.") % [
                graph.counts.total_edges,
                graph.movement_params.name,
            ]

func to_string() -> String:
    return "%s { count=%s }" % [
        InspectorItemType.get_string(type),
        graph.counts.total_edges,
    ]

func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    Gs.logger.error(
            "find_and_expand_controller should not be called for " + \
            "EDGES_GROUP.")
    return false

func _create_children_inner() -> void:
    EdgesWithIncreasingJumpHeightGroupItemController.new(
            tree_item,
            tree,
            graph)
    EdgesWithoutIncreasingJumpHeightGroupItemController.new(
            tree_item,
            tree,
            graph)
    EdgesWithOneStepGroupItemController.new(
            tree_item,
            tree,
            graph)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    return get_annotation_elements_from_graph(graph)

static func get_annotation_elements_from_graph(graph: PlatformGraph) -> Array:
    var elements := []
    var element: EdgeAnnotationElement
    for origin_surface in graph.surfaces_set:
        for origin_node in graph.surfaces_to_outbound_nodes[origin_surface]:
            for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
                for edge in graph.nodes_to_nodes_to_edges[origin_node][ \
                        destination_node]:
                    element = EdgeAnnotationElement.new(
                            edge,
                            true,
                            false,
                            true,
                            false)
                    elements.push_back(element)
    return elements
