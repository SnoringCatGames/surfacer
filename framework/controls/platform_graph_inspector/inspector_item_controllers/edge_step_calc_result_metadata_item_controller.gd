extends InspectorItemController
class_name EdgeStepCalcResultMetadataItemController

const TYPE := InspectorItemType.EDGE_STEP_CALC_RESULT_METADATA
const IS_LEAF := false
const STARTS_COLLAPSED := false

var edge_or_edge_attempt
var step_result_metadata: EdgeStepCalcResultMetadata
var step_item_factory
var background_color: Color

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        edge_or_edge_attempt, \
        step_result_metadata: EdgeStepCalcResultMetadata, \
        step_item_factory) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    assert(step_result_metadata != null)
    self.edge_or_edge_attempt = edge_or_edge_attempt
    self.step_result_metadata = step_result_metadata
    self.step_item_factory = step_item_factory
    self.background_color = _calculate_background_color(step_result_metadata)
    self.tree_item.set_custom_bg_color( \
            0, \
            background_color)
    _post_init()

func to_string() -> String:
    return "%s { edge_step_calc_result_type=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeStepCalcResultType.get_type_string( \
                step_result_metadata.edge_step_calc_result_type), \
    ]

func get_text() -> String:
    return _get_text_for_description_index(0)

func get_description() -> String:
    var description := ""
    
    var description_list := step_result_metadata.get_description_list()
    for i in range(description_list.size()):
        description += \
                description_list[i].replace("\n                ", " ") + " "
    
    if step_result_metadata.get_is_backtracking():
        description += \
                "This step is the start of a backtracking sequence, to " + \
                "consider a higher jump height."
    
    if step_result_metadata.get_replaced_a_fake():
        description += \
                "Replaced a \"fake\" intermediate constraint (a fake " + \
                "constraint is a point along an end of a surface which " + \
                "wouldn't actually be efficient to move through, since " + \
                "movement should instead travel more directly through the " + \
                "following constraint). "
    
    return description

func _get_text_for_description_index(description_index: int) -> String:
    match description_index:
        0:
            return "%s: %s%s%s" % [ \
                    step_result_metadata.index + 1, \
                    "[BT] " if \
                            step_result_metadata.get_is_backtracking() else \
                            "", \
                    "[RF] " if \
                            step_result_metadata.get_replaced_a_fake() else \
                            "", \
                    step_result_metadata.get_description_list()[0] \
                            .replace("\n                ", " "), \
                ]
        1:
            return "(%s: %s)" % [ \
                    step_result_metadata.index + 1, \
                    step_result_metadata.get_description_list()[1] \
                            .replace("\n                ", " "), \
                ]
        _:
            Utils.error()
            return ""

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Utils.error( \
            "find_and_expand_controller should not be called for " + \
            "EDGE_STEP_CALC_RESULT_METADATA.")
    return false

func get_has_children() -> bool:
    return !step_result_metadata.children_step_attempts.empty()

func _create_children_inner() -> void:
    for child_step_result_metadata in \
            step_result_metadata.children_step_attempts:
        step_item_factory.create( \
                tree_item, \
                tree, \
                graph, \
                edge_or_edge_attempt, \
                child_step_result_metadata, \
                step_item_factory)
    
    if step_result_metadata.get_description_list().size() > 1:
        DescriptionItemController.new( \
                tree_item, \
                tree, \
                graph, \
                _get_text_for_description_index(1), \
                get_description(), \
                funcref(self, "get_annotation_elements"), \
                null, \
                background_color)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var element := EdgeStepAnnotationElement.new( \
            step_result_metadata, \
            false)
    return [element]

static func _calculate_background_color( \
        step_result_metadata: EdgeStepCalcResultMetadata) -> Color:
    # Hue transitions evenly from start to end.
    var total_step_count := \
            step_result_metadata.edge_result_metadata.total_step_count
    var step_ratio := \
            (step_result_metadata.index / (total_step_count - 1.0)) if \
            total_step_count > 1 else \
            1.0
    var step_hue: float = \
            AnnotationElementDefaults.STEP_HUE_START + \
            (AnnotationElementDefaults.STEP_HUE_END - \
                    AnnotationElementDefaults.STEP_HUE_START) * \
            step_ratio
    return Color.from_hsv( \
            step_hue, \
            AnnotationElementDefaults \
                    .INSPECTOR_STEP_CALC_ITEM_BACKGROUND_COLOR.s, \
            AnnotationElementDefaults \
                    .INSPECTOR_STEP_CALC_ITEM_BACKGROUND_COLOR.v, \
            1.0)
