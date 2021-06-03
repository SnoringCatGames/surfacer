class_name SurfaceParserGroupItemController
extends InspectorItemController

const TYPE := InspectorItemType.SURFACE_PARSER_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := false
const PREFIX := "Surface parser"

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
    return "Some stats on the time to parse the surfaces in the level."

func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    Gs.logger.error(
            "find_and_expand_controller should not be called for " +
            "SURFACE_PARSER_GROUP.")
    return false

func _create_children_inner() -> void:
    for metric in Surfacer.surface_parser_metric_keys:
        if Gs.profiler.is_timing(metric):
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

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    # Do nothing.
    return []

func _get_annotation_elements_for_description_item() -> Array:
    # Do nothing.
    return []
