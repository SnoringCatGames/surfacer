extends InspectorItemController
class_name AnalyticsTopLevelGroupItemController

const TYPE := InspectorItemType.ANALYTICS_TOP_LEVEL_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := false
const PREFIX := "Analytics"

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
    return ("Some stats on the time to parse the platform graph for the " + \
            "%s player.") % [ \
        graph.movement_params.name, \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Utils.error( \
            "find_and_expand_controller should not be called for " + \
            "ANALYTICS_TOP_LEVEL_GROUP.")
    return false

func _create_children_inner() -> void:
    for metric in AnalyticsMetric.values():
        _create_child( \
                AnalyticsMetric.get_type_string(metric), \
                Analytics.get_timing(metric))

func _create_child( \
        label: String, \
        value: int, \
        suffix := "ms") -> void:
    var text = "%s%s: %s" % [ \
        value, \
        suffix, \
        label, \
    ]
    DescriptionItemController.new( \
            tree_item, \
            tree, \
            graph, \
            text, \
            text, \
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
