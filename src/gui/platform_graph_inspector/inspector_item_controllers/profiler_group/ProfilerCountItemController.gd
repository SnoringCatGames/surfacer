class_name ProfilerCountItemController
extends InspectorItemController

const TYPE := InspectorItemType.PROFILER_COUNT
const IS_LEAF := true
const STARTS_COLLAPSED := true

var metric: String
var metadata_container: EdgeCalcResultMetadata

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        metric: String, \
        metadata_container = null) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.metric = metric
    self.metadata_container = metadata_container
    _post_init()

func get_text() -> String:
    return "%s: %s" % [ \
        Gs.profiler.get_count(metric, metadata_container), \
        metric, \
    ]

func get_description() -> String:
    return ("The total number of times the %s event happened while " + \
            "parsing the platform graph for the %s player.") % [ \
        metric, \
        graph.movement_params.name, \
    ]

func get_has_children() -> bool:
    return false

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Gs.logger.error( \
            "find_and_expand_controller should not be called for " + \
            "PROFILER_COUNT.")
    return false

func _create_children_inner() -> void:
    # Do nothing.
    pass

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    # Do nothing.
    return []

func _get_annotation_elements_for_description_item() -> Array:
    # Do nothing.
    return []
