class_name PlatformGraphItemController
extends InspectorItemController


const TYPE := InspectorItemType.PLATFORM_GRAPH
const IS_LEAF := false
const STARTS_COLLAPSED := true
const PREFIX := "Platform graph"

# Dictionary<Surface, Dictionary<Surface, Dictionary<int,
#         Array<InterSurfaceEdgesResult>>>>
var surfaces_to_surfaces_to_edge_types_to_edges_results := {}

var edges_item_controller: EdgesGroupItemController
var surfaces_item_controller: SurfacesGroupItemController
var profiler_item_controller: ProfilerGroupItemController


func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph) \
        .(
        TYPE,
        IS_LEAF,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph) -> void:
    _populate_surfaces_to_surfaces_to_edge_types_to_edge_results_mappings()
    _post_init()


func get_text() -> String:
    return "%s [%s]" % [
        PREFIX,
        graph.movement_params.character_category_name,
    ]


func get_description() -> String:
    return ("A platform graph consists of nodes, which are positions " +
            "along surfaces, and edges, which are movements between these " +
            "surface positions. Since different characters have different " +
            "movement parameters, a graph is specific to a given character.")


func to_string() -> String:
    return "%s { character_category_name=%s }" % [
        InspectorItemType.get_string(type),
        graph.movement_params.character_category_name,
    ]


func on_item_expanded() -> void:
    _populate_trajectories()
    .on_item_expanded()


func _populate_trajectories() -> void:
    for origin_node in graph.nodes_to_nodes_to_edges:
        for edges in graph.nodes_to_nodes_to_edges[origin_node].values():
            for edge in edges:
                edge.populate_trajectory(graph.collision_params)


func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    expand()
    _trigger_find_and_expand_controller_recursive(
            search_type,
            metadata)
    return true


func _find_and_expand_controller_recursive(
        search_type: int,
        metadata: Dictionary) -> void:
    # TODO: Create separate metadata classes for InspectorSearchType metadata,
    #       rather than relying on these asserts here.
    match search_type:
        InspectorSearchType.EDGE:
            assert(metadata.has("origin_surface") and \
                    metadata.has("destination_surface") and \
                    metadata.has("start") and \
                    metadata.has("end") and \
                    metadata.has("edge_type"))
            surfaces_item_controller.find_and_expand_controller(
                    search_type,
                    metadata)
            
        InspectorSearchType.ORIGIN_SURFACE, \
        InspectorSearchType.DESTINATION_SURFACE:
            assert(metadata.has("origin_surface"))
            if graph.surfaces_set.has(metadata.origin_surface):
                surfaces_item_controller.find_and_expand_controller(
                        search_type,
                        metadata)
            else:
                Sc.logger.error("Invalid Surface: %s" % \
                        metadata.origin_surface.to_string())
          
        InspectorSearchType.EDGES_GROUP:
            edges_item_controller.select()
        
        _:
            Sc.logger.error("Invalid InspectorSearchType: %s" % \
                    InspectorSearchType.get_string(search_type))


func _create_children_inner() -> void:
    edges_item_controller = EdgesGroupItemController.new(
            tree_item,
            tree,
            graph,
            surfaces_to_surfaces_to_edge_types_to_edges_results)
    surfaces_item_controller = SurfacesGroupItemController.new(
            tree_item,
            tree,
            graph,
            surfaces_to_surfaces_to_edge_types_to_edges_results)
    profiler_item_controller = ProfilerGroupItemController.new(
            tree_item,
            tree,
            graph)


# Parse the inter-surface edge-calculation results into a structure that's
# easier to use from the inspector.
func _populate_surfaces_to_surfaces_to_edge_types_to_edge_results_mappings() -> \
        void:
    for origin_surface in graph.surfaces_to_inter_surface_edges_results:
        var destination_surfaces_to_edge_types_to_edges_results: Dictionary
        if !surfaces_to_surfaces_to_edge_types_to_edges_results.has(
                origin_surface):
            destination_surfaces_to_edge_types_to_edges_results = {}
            surfaces_to_surfaces_to_edge_types_to_edges_results \
                    [origin_surface] = \
                    destination_surfaces_to_edge_types_to_edges_results
        else:
            destination_surfaces_to_edge_types_to_edges_results = \
                    surfaces_to_surfaces_to_edge_types_to_edges_results \
                            [origin_surface]
        
        for inter_surface_edges_results in \
                graph.surfaces_to_inter_surface_edges_results[origin_surface]:
            var destination_surface: Surface = \
                    inter_surface_edges_results.destination_surface
            var edge_type: int = inter_surface_edges_results.edge_type
            
            var edge_types_to_edges_results: Dictionary
            if !destination_surfaces_to_edge_types_to_edges_results.has(
                    destination_surface):
                edge_types_to_edges_results = {}
                destination_surfaces_to_edge_types_to_edges_results \
                        [destination_surface] = \
                        edge_types_to_edges_results
            else:
                edge_types_to_edges_results = \
                        destination_surfaces_to_edge_types_to_edges_results \
                                [destination_surface]
            
            var edges_results: Array
            if !edge_types_to_edges_results.has(edge_type):
                edges_results = []
                edge_types_to_edges_results[edge_type] = edges_results
            else:
                edges_results = edge_types_to_edges_results[edge_type]
            
            edges_results.push_back(inter_surface_edges_results)


func _destroy_children_inner() -> void:
    edges_item_controller._destroy()
    edges_item_controller = null
    surfaces_item_controller._destroy()
    surfaces_item_controller = null
    profiler_item_controller._destroy()
    profiler_item_controller = null


func get_annotation_elements() -> Array:
    return get_annotation_elements_from_graph(graph)


static func get_annotation_elements_from_graph(graph: PlatformGraph) -> Array:
    var result := SurfacesGroupItemController \
            .get_annotation_elements_from_graph(graph)
    Sc.utils.concat(
            result,
            EdgesGroupItemController \
                    .get_annotation_elements_from_graph(graph))
    return result
