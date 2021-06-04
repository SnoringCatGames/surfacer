class_name ProfilerTimingItemController
extends InspectorItemController

const TYPE := InspectorItemType.PROFILER_TIMING
const IS_LEAF := false
const STARTS_COLLAPSED := true

var metric: String
var metadata_container: EdgeCalcResultMetadata


func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        metric: String,
        metadata_container = null) \
        .(
        TYPE,
        IS_LEAF,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph) -> void:
    self.metric = metric
    self.metadata_container = metadata_container
    _post_init()


func get_text() -> String:
    return "%sms: %s" % [
        Gs.profiler.get_sum(metric, metadata_container),
        metric,
    ]


func get_description() -> String:
    return ("The total time spent on the %s stage while parsing the " +
            "platform graph for the %s player.") % [
        metric,
        graph.movement_params.name,
    ]


func get_has_children() -> bool:
    return Gs.profiler.get_count(metric, metadata_container) > 1


func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    Gs.logger.error(
            "find_and_expand_controller should not be called for " +
            "PROFILER_TIMING.")
    return false


func _create_children_inner() -> void:
    if !get_has_children():
        return
    
    _create_child(
            "Total",
            Gs.profiler.get_sum(metric, metadata_container))
    _create_child(
            "Average",
            Gs.profiler.get_mean(metric, metadata_container))
    _create_child(
            "Count",
            Gs.profiler.get_count(metric, metadata_container),
            "")
    _create_child(
            "Min",
            Gs.profiler.get_min(metric, metadata_container))
    _create_child(
            "Max",
            Gs.profiler.get_max(metric, metadata_container))


func _create_child(
        label: String,
        value: float,
        suffix := "ms") -> void:
    var text := "%s%s: %s" % [
        value,
        suffix,
        label,
    ]
    var description := text + " " + metric
    DescriptionItemController.new(
            tree_item,
            tree,
            graph,
            text,
            description,
            funcref(self,
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
