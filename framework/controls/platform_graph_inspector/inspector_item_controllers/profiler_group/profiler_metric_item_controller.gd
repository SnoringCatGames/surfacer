extends InspectorItemController
class_name ProfilerMetricItemController

const TYPE := InspectorItemType.PROFILER_METRIC
const IS_LEAF := false
const STARTS_COLLAPSED := true

var metric := ProfilerMetric.UNKNOWN

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        metric: int) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.metric = metric
    _post_init()

func get_text() -> String:
    return "%sms: %s" % [ \
        Profiler.get_sum(metric), \
        ProfilerMetric.get_type_string(metric), \
    ]

func get_description() -> String:
    return ("The total time spent on the the %s stage while parsing the " + \
            "platform graph for the %s player.") % [ \
        ProfilerMetric.get_type_string(metric), \
        graph.movement_params.name, \
    ]

func get_has_children() -> bool:
    return Profiler.get_count(metric) > 1

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Utils.error( \
            "find_and_expand_controller should not be called for " + \
            "PROFILER_METRIC.")
    return false

func _create_children_inner() -> void:
    if !get_has_children():
        return
    
    _create_child( \
            "Total", \
            Profiler.get_sum(metric))
    _create_child( \
            "Average", \
            Profiler.get_mean(metric))
    _create_child( \
            "Count", \
            Profiler.get_count(metric), \
            "")
    _create_child( \
            "Min", \
            Profiler.get_min(metric))
    _create_child( \
            "Max", \
            Profiler.get_max(metric))

func _create_child( \
        label: String, \
        value: float, \
        suffix := "ms") -> void:
    var text := "%s%s: %s" % [ \
        value, \
        suffix, \
        label, \
    ]
    var description := text + " " + ProfilerMetric.get_type_string(metric)
    DescriptionItemController.new( \
            tree_item, \
            tree, \
            graph, \
            text, \
            description, \
            funcref(self, \
                    "_get_annotation_elements_for_description_item"))

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    # Do nothing.
    return []

func _get_annotation_elements_for_description_item() -> Array:
    # Do nothing.
    return []
