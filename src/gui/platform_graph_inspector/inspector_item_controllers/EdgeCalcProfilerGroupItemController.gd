class_name EdgeCalcProfilerGroupItemController
extends InspectorItemController

const TYPE := InspectorItemType.EDGE_CALC_PROFILER_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := true
const PREFIX := "Profiler"

var edge_result_metadata: EdgeCalcResultMetadata


func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        edge_result_metadata: EdgeCalcResultMetadata) \
        .(
        TYPE,
        IS_LEAF,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph) -> void:
    self.edge_result_metadata = edge_result_metadata
    _post_init()


func get_text() -> String:
    return PREFIX


func get_description() -> String:
    return "Some stats on the time to calculate this edge."


func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    Gs.logger.error(
            "find_and_expand_controller should not be called for " +
            "EDGE_CALC_PROFILER_GROUP.")
    return false


func _create_children_inner() -> void:
    for metric in Gs.profiler.get_preregistered_metric_keys():
        if Surfacer.surface_parser_metric_keys.find(metric) >= 0 or \
                Gs.profiler.get_count(metric, edge_result_metadata) == 0:
            continue
        if Gs.profiler.is_timing(metric):
            ProfilerTimingItemController.new(
                    tree_item,
                    tree,
                    graph,
                    metric,
                    edge_result_metadata)
        else:
            ProfilerCountItemController.new(
                    tree_item,
                    tree,
                    graph,
                    metric,
                    edge_result_metadata)


func _destroy_children_inner() -> void:
    # Do nothing.
    pass


func get_annotation_elements() -> Array:
    # Do nothing.
    return []


func _get_annotation_elements_for_description_item() -> Array:
    # Do nothing.
    return []
