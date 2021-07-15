class_name ProfilerGroupItemController
extends InspectorItemController


const TYPE := InspectorItemType.PROFILER_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := false
const PREFIX := "Profiler"

var surface_parser_item_controller: SurfaceParserGroupItemController
var global_counts_item_controller: GlobalCountsGroupItemController


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
    return ("Some stats on the time to parse the platform graph for the " +
            "%s player.") % [
        graph.movement_params.name,
    ]


func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    Sc.logger.error(
            "find_and_expand_controller should not be called for " +
            "PROFILER_GROUP.")
    return false


func _create_children_inner() -> void:
    for metric in Sc.profiler.get_preregistered_metric_keys():
        if Su.surface_parser_metric_keys.find(metric) >= 0:
            continue
        if Sc.profiler.is_timing(metric):
            ProfilerTimingItemController.new(
                    tree_item,
                    tree,
                    graph,
                    metric)
        else:
            ProfilerCountItemController.new(
                    tree_item,
                    tree,
                    graph,
                    metric)
    
    surface_parser_item_controller = \
            SurfaceParserGroupItemController.new(
                    tree_item,
                    tree,
                    graph)
    
    global_counts_item_controller = \
            GlobalCountsGroupItemController.new(
                    tree_item,
                    tree,
                    graph)


func _destroy_children_inner() -> void:
    surface_parser_item_controller = null
    global_counts_item_controller = null


func get_annotation_elements() -> Array:
    # Do nothing.
    return []


func _get_annotation_elements_for_description_item() -> Array:
    # Do nothing.
    return []
