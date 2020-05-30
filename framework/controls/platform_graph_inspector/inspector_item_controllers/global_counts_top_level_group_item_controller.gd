extends InspectorItemController
class_name GlobalCountsTopLevelGroupItemController

const TYPE := InspectorItemType.GLOBAL_COUNTS_TOP_LEVEL_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := false
const PREFIX := "Global counts"

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
    return PREFIX

func get_description() -> String:
    return ("Some stats on the overall platform graph for the %s " + \
            "player.") % [ \
        graph.movement_params.name, \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Utils.error( \
            "find_and_expand_controller should not be called for " + \
            "GLOBAL_COUNTS_TOP_LEVEL_GROUP.")
    return false

func _create_children_inner() -> void:
    var text: String = "%s total surfaces" % graph.counts.total_surfaces
    DescriptionItemController.new( \
            tree_item, \
            tree, \
            graph, \
            text, \
            text, \
            funcref(self, \
                    "_get_annotation_elements_for_surfaces_description_item"))
    text = "%s total edges" % graph.counts.total_edges
    DescriptionItemController.new( \
            tree_item, \
            tree, \
            graph, \
            text, \
            text, \
            funcref(self, \
                    "_get_annotation_elements_for_edges_description_item"))
    
    var type_name: String
    for edge_type in EdgeType.values():
        if InspectorItemController.EDGE_TYPES_TO_SKIP.find(edge_type) >= 0:
            continue
        
        type_name = EdgeType.get_type_string(edge_type)
        text = "%s %ss" % [ \
            graph.counts[type_name], \
            type_name, \
        ]
        DescriptionItemController.new( \
                tree_item, \
                tree, \
                graph, \
                text, \
                text, \
                funcref(self, "_get_annotation_elements_for_edge_type_description_item"), \
                edge_type)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var result := SurfacesTopLevelGroupItemController.get_annotation_elements_from_graph(graph)
    Utils.concat( \
            result, \
            EdgesTopLevelGroupItemController.get_annotation_elements_from_graph(graph))
    return result

func _get_annotation_elements_for_surfaces_description_item() -> Array:
    return SurfacesTopLevelGroupItemController.get_annotation_elements_from_graph(graph)

func _get_annotation_elements_for_edges_description_item() -> Array:
    return EdgesTopLevelGroupItemController.get_annotation_elements_from_graph(graph)

func _get_annotation_elements_for_edge_type_description_item(edge_type: int) -> Array:
    return EdgeTypeInEdgesGroupItemController.get_annotation_elements_from_graph_and_type( \
            graph, 
            edge_type)
