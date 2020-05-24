extends InspectorItemController
class_name EdgeStepCalcResultMetadataItemController

const TYPE := InspectorItemType.EDGE_STEP_CALC_RESULT_METADATA
const IS_LEAF := false
const STARTS_COLLAPSED := false

var edge_or_edge_attempt
var step_result_metadata: EdgeStepCalcResultMetadata
var step_item_factory

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
    _post_init()

func to_string() -> String:
    return "%s { edge_step_calc_result_type=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeStepCalcResultType.get_type_string(step_result_metadata.edge_step_calc_result_type), \
    ]

func get_text() -> String:
    return _get_text_for_description_index(0)

func _get_text_for_description_index(description_index: int) -> String:
    return "%s: %s%s%s" % [ \
            step_result_metadata.index + 1, \
            "[BT] " if \
                    step_result_metadata.get_is_backtracking() and \
                            description_index == 0 else \
                    "", \
            "[RF] " if \
                    step_result_metadata.get_replaced_a_fake() and \
                            description_index == 0 else \
                    "", \
            step_result_metadata.get_description_list()[description_index], \
        ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Utils.error("find_and_expand_controller should not be called for EDGE_STEP_CALC_RESULT_METADATA.")
    return false

func get_has_children() -> bool:
    return !step_result_metadata.children_step_attempts.empty()

func _create_children_inner() -> void:
    for child_step_result_metadata in step_result_metadata.children_step_attempts:
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
                funcref(self, "get_annotation_elements"))

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var element := EdgeStepAnnotationElement.new( \
            step_result_metadata, \
            false)
    return [element]
