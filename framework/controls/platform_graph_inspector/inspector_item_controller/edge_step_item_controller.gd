extends InspectorItemController
class_name EdgeStepItemController

const TYPE := InspectorItemType.EDGE_STEP
const STARTS_COLLAPSED := true

var step_result_metadata: EdgeStepCalcResultMetadata

func _init( \
        tree_item: TreeItem, \
        tree: Tree, \
        step_result_metadata: EdgeStepCalcResultMetadata) \
        .( \
        TYPE, \
        STARTS_COLLAPSED, \
        tree_item, \
        tree) -> void:
    self.step_result_metadata = step_result_metadata
    _update_text()

func to_string() -> String:
    return "%s { %s [%s, %s] }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeType.get_type_string(failed_edge_attempt.edge_type), \
        str(failed_edge_attempt.start), \
        str(failed_edge_attempt.end), \
    ]

func get_text() -> String:
    return "%s [%s, %s]" % [ \
        EdgeCalcResultType.get_result_string( \
                failed_edge_attempt.edge_calc_result_type) if \
        failed_edge_attempt.edge_calc_result_type != \
                EdgeCalcResultType.WAYPOINT_INVALID else \
        WaypointValidity.get_validity_string( \
                failed_edge_attempt.waypoint_validity), \
        str(failed_edge_attempt.start), \
        str(failed_edge_attempt.end), \
    ]

func _create_children() -> void:
    # FIXME: ----------------------------
    pass

func _destroy_children() -> void:
    for child in tree_item.get_children():
        child.get_metadata(0).destroy()

func _draw_annotations() -> void:
    # FIXME: -----------------
    pass




# FIXME: -----------------------------------------------------------
#func _draw_step_items_for_edge_attempt( \
#        edge_attempt: EdgeCalcResultMetadata, \
#        edge_item: TreeItem) -> void:
#    if !edge_attempt.failed_before_creating_steps:
#        # Draw rows for each step-attempt.
#        for step_attempt in edge_attempt.children_step_attempts:
#            _draw_step_item( \
#                    step_attempt, \
#                    edge_item)
#    else:
#        # Draw a message for the invalid edge.
#        var tree_item := tree.create_item(edge_item)
#        tree_item.set_text( \
#                0, \
#                EdgeCalculationTrajectoryAnnotator.INVALID_EDGE_TEXT)
#
#func _draw_step_item( \
#        step_attempt: EdgeStepCalcResultMetadata, \
#        parent_item: TreeItem) -> void:
#    # Draw the row for the given step-attempt.
#    var tree_item := tree.create_item(parent_item)
#    var text := _get_step_item_text( \
#            step_attempt, \
#            0, \
#            false)
#    tree_item.set_text( \
#            0, \
#            text)
#    tree_item.set_metadata( \
#            0, \
#            step_attempt)
#
#    # Recursively draw rows for each child step-attempt.
#    for child_step_attempt in step_attempt.children_step_attempts:
#        _draw_step_item( \
#                child_step_attempt, \
#                tree_item)
#
#    if step_attempt.description_list.size() > 1:
#        # Draw a closing row for the given step-attempt.
#        var tree_item_2 := tree.create_item(parent_item)
#        text = _get_step_item_text( \
#                step_attempt, \
#                1, \
#                false)
#        tree_item_2.set_text( \
#                0, \
#                text)
#        tree_item.set_metadata( \
#                0, \
#                step_attempt)
#
#func _select_edge_step_items_from_tree_item(item: TreeItem) -> void:
#    var step_result: EdgeStepCalcResultMetadata = item.get_metadata(0)
#    assert(step_result is EdgeStepCalcResultMetadata)
#
#    current_selected_step_items = []
#    for child in item.get_parent():
#        if child.get_metadata() == step_result:
#            current_selected_step_items.push_back(child)
#
#    _set_selected_step_items_text( \
#            current_selected_step_items, \
#            step_result)
#
#static func _set_selected_step_items_text( \
#        items: Array, \
#        step_result: EdgeStepCalcResultMetadata) -> void:
#    for i in range(items.size()):
#        items[i].set_text( \
#                0, \
#                _get_step_item_text( \
#                        step_result, \
#                        i, \
#                        true))
#
#func _clear_selected_step_items() -> void:
#    # Unmark all previously selected tree items.
#    for i in range(current_selected_step_items.size()):
#        var tree_item: TreeItem = current_selected_step_items[i]
#        var step_attempt: EdgeStepCalcResultMetadata = tree_item.get_metadata(0)
#        var text := _get_step_item_text( \
#                step_attempt, \
#                i, \
#                false)
#        tree_item.set_text( \
#                0, \
#                text)
#
#    current_selected_step_items.clear()
#
#static func _get_step_item_text( \
#        step_attempt: EdgeStepCalcResultMetadata, \
#        description_index: int, \
#        is_selected: bool) -> String:
#    return "%s%s: %s%s%s" % [ \
#            "*" if \
#                    is_selected else \
#                    "",
#            step_attempt.index + 1, \
#            "[BT] " if \
#                    step_attempt.is_backtracking and description_index == 0 \
#                    else "", \
#            "[RF] " if \
#                    step_attempt.replaced_a_fake and description_index == 0 else \
#                    "", \
#            step_attempt.description_list[description_index], \
#        ]
