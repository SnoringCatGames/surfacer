class_name GlobalCountsGroupItemController
extends InspectorItemController


const TYPE := InspectorItemType.GLOBAL_COUNTS_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := false
const PREFIX := "Global counts"


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
    _post_init()


func get_text() -> String:
    return PREFIX


func get_description() -> String:
    return ("Some stats on the overall platform graph for the %s " +
            "character.") % [
        graph.movement_params.character_category_name,
    ]


func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    Sc.logger.error(
            "find_and_expand_controller should not be called for " +
            "GLOBAL_COUNTS_GROUP.")
    return false


func _create_children_inner() -> void:
    var text: String = "%s total surfaces" % graph.counts.total_surfaces
    DescriptionItemController.new(
            tree_item,
            tree,
            graph,
            text,
            text,
            funcref(self,
                    "_get_annotation_elements_for_surfaces_description_item"))
    text = "%s total edges" % graph.counts.total_edges
    DescriptionItemController.new(
            tree_item,
            tree,
            graph,
            text,
            text,
            funcref(self,
                    "_get_annotation_elements_for_edges_description_item"))
    
    for edge_type in EdgeType.values():
        if InspectorItemController.EDGE_TYPES_TO_SKIP.find(edge_type) >= 0:
            continue
        
        var type_name := EdgeType.get_string(edge_type)
        text = "%s %ss" % [
            graph.counts[type_name],
            type_name,
        ]
        DescriptionItemController.new(
                tree_item,
                tree,
                graph,
                text,
                text,
                funcref(self, 
                        "_get_annotation_elements_for_edge_type_description_item"),
                edge_type)


func _destroy_children_inner() -> void:
    # Do nothing.
    pass


func get_annotation_elements() -> Array:
    var result := SurfacesGroupItemController \
            .get_annotation_elements_from_graph(graph)
    Sc.utils.concat(
            result,
            EdgesGroupItemController.get_annotation_elements_from_graph(graph))
    return result


func _get_annotation_elements_for_surfaces_description_item() -> Array:
    return SurfacesGroupItemController \
            .get_annotation_elements_from_graph(graph)


func _get_annotation_elements_for_edges_description_item() -> Array:
    return EdgesGroupItemController.get_annotation_elements_from_graph(graph)


func _get_annotation_elements_for_edge_type_description_item(
        edge_type: int) -> Array:
    return EdgeTypeInEdgesGroupItemController \
            .get_annotation_elements_from_graph_and_type(
                    graph,
                    edge_type)
