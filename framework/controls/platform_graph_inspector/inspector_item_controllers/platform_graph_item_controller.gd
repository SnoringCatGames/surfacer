extends InspectorItemController
class_name PlatformGraphItemController

const TYPE := InspectorItemType.PLATFORM_GRAPH
const IS_LEAF := false
const STARTS_COLLAPSED := false
const PREFIX := "Platform graph"

# Dictionary<Surface, Dictionary<Surface, Dictionary<EdgeType, Array<Edge>>>>
var surfaces_to_surfaces_to_edge_types_to_valid_edges := {}
# Dictionary<Surface, Dictionary<Surface, Dictionary<EdgeType, Array<FailedEdgeAttempt>>>>
var surfaces_to_surfaces_to_edge_types_to_failed_edges := {}

var edges_item_controller: EdgesTopLevelGroupItemController
var surfaces_item_controller: SurfacesTopLevelGroupItemController
var global_counts_item_controller: GlobalCountsTopLevelGroupItemController

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
    _populate_surfaces_to_surfaces_to_edge_types_to_edges_mappings()
    _post_init()

func get_text() -> String:
    return "%s [%s]" % [ \
        PREFIX, \
        graph.movement_params.name, \
    ]

func to_string() -> String:
    return "%s { player_name=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        graph.movement_params.name, \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    expand()
    call_deferred( \
            "find_and_expand_controller_recursive", \
            search_type, \
            metadata)
    return true

func find_and_expand_controller_recursive( \
        search_type: int, \
        metadata: Dictionary) -> void:
    match search_type:
        InspectorSearchType.EDGE:
            assert(metadata.has("origin_surface") and \
                    metadata.has("destination_surface") and \
                    metadata.has("start") and \
                    metadata.has("end") and \
                    metadata.has("edge_type"))
            surfaces_item_controller.find_and_expand_controller( \
                    search_type, \
                    metadata)
            
        InspectorSearchType.SURFACE:
            assert(metadata.has("surface"))
            if graph.surfaces_set.has(metadata.surface):
                surfaces_item_controller.find_and_expand_controller( \
                        search_type, \
                        metadata)
            else:
                Utils.error("Invalid Surface: %s" % metadata.surface.to_string())
          
        InspectorSearchType.EDGES_TOP_LEVEL_GROUP:
            edges_item_controller.select()
        
        _:
            Utils.error("Invalid InspectorSearchType: %s" % \
                    InspectorSearchType.get_type_string(search_type))

func _create_children_inner() -> void:
    edges_item_controller = EdgesTopLevelGroupItemController.new( \
            tree_item, \
            tree, \
            graph)
    surfaces_item_controller = SurfacesTopLevelGroupItemController.new( \
            tree_item, \
            tree, \
            graph, \
            surfaces_to_surfaces_to_edge_types_to_valid_edges, \
            surfaces_to_surfaces_to_edge_types_to_failed_edges)
    global_counts_item_controller = GlobalCountsTopLevelGroupItemController.new( \
            tree_item, \
            tree, \
            graph)

func _populate_surfaces_to_surfaces_to_edge_types_to_edges_mappings() -> void:
    var destination_surface: Surface
    var edge: Edge
    var destination_surfaces_to_edge_types_to_edges: Dictionary
    var edge_types_to_edges: Dictionary
    var edges: Array
    
    surfaces_to_surfaces_to_edge_types_to_valid_edges.clear()
    surfaces_to_surfaces_to_edge_types_to_failed_edges.clear()
    
    # Populate a mapping of valid edges.
    for origin_surface in graph.surfaces_to_outbound_nodes:
        for origin_node in graph.surfaces_to_outbound_nodes[origin_surface]:
            for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
                destination_surface = destination_node.surface
                edge = graph.nodes_to_nodes_to_edges[origin_node][destination_node]
                
                if !surfaces_to_surfaces_to_edge_types_to_valid_edges.has(origin_surface):
                    destination_surfaces_to_edge_types_to_edges = {}
                    surfaces_to_surfaces_to_edge_types_to_valid_edges[origin_surface] = \
                            destination_surfaces_to_edge_types_to_edges
                else:
                    destination_surfaces_to_edge_types_to_edges = \
                            surfaces_to_surfaces_to_edge_types_to_valid_edges[origin_surface]
                
                if !destination_surfaces_to_edge_types_to_edges.has(destination_surface):
                    edge_types_to_edges = {}
                    destination_surfaces_to_edge_types_to_edges[destination_surface] = \
                            edge_types_to_edges
                else:
                    edge_types_to_edges = \
                            destination_surfaces_to_edge_types_to_edges[destination_surface]
                
                if !edge_types_to_edges.has(edge.type):
                    edges = []
                    edge_types_to_edges[edge.type] = edges
                else:
                    edges = edge_types_to_edges[edge.type]
                
                edges.push_back(edge)
    
    # Populate a mapping of failed edge attempts.
    for origin_surface in graph.surfaces_set:
        for failed_edge_attempt in graph.surfaces_to_failed_edge_attempts[origin_surface]:
            destination_surface = failed_edge_attempt.destination_surface
            
            if !surfaces_to_surfaces_to_edge_types_to_failed_edges.has(origin_surface):
                destination_surfaces_to_edge_types_to_edges = {}
                surfaces_to_surfaces_to_edge_types_to_failed_edges[origin_surface] = \
                        destination_surfaces_to_edge_types_to_edges
            else:
                destination_surfaces_to_edge_types_to_edges = \
                        surfaces_to_surfaces_to_edge_types_to_failed_edges[origin_surface]
            
            if !destination_surfaces_to_edge_types_to_edges.has(destination_surface):
                edge_types_to_edges = {}
                destination_surfaces_to_edge_types_to_edges[destination_surface] = \
                        edge_types_to_edges
            else:
                edge_types_to_edges = \
                        destination_surfaces_to_edge_types_to_edges[destination_surface]
            
            if !edge_types_to_edges.has(failed_edge_attempt.edge_type):
                edges = []
                edge_types_to_edges[failed_edge_attempt.edge_type] = edges
            else:
                edges = edge_types_to_edges[failed_edge_attempt.edge_type]
            
            edges.push_back(failed_edge_attempt)

func _destroy_children_inner() -> void:
    edges_item_controller.destroy()
    edges_item_controller = null
    surfaces_item_controller.destroy()
    surfaces_item_controller = null
    global_counts_item_controller.destroy()
    global_counts_item_controller = null

func get_annotation_elements() -> Array:
    return get_annotation_elements_from_graph(graph)

static func get_annotation_elements_from_graph(graph: PlatformGraph) -> Array:
    var result := SurfacesTopLevelGroupItemController.get_annotation_elements_from_graph(graph)
    Utils.concat( \
            result, \
            EdgesTopLevelGroupItemController.get_annotation_elements_from_graph(graph))
    return result
