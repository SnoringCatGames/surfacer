extends Node2D
class_name IntraEdgeCalculationTreeViewAnnotator

signal step_selected

var global # TODO: Add type back
var graph: PlatformGraph
var step_tree_view: Tree
var step_tree_root: TreeItem

# Dictionary<TreeItem, MovementCalcStepDebugState>
var tree_item_to_step_attempt := {}
# Dictionary<MovementCalcStepDebugState, Array<TreeItem>>
var step_attempt_to_tree_items := {}

var current_highlighted_tree_items: Array

func _init(graph: PlatformGraph) -> void:
    self.graph = graph

func _ready() -> void:
    global = $"/root/Global"
    
    step_tree_view = Tree.new()
    step_tree_view.rect_min_size = Vector2(0.0, DebugPanel.SECTIONS_HEIGHT)
    step_tree_view.hide_root = true
    step_tree_view.hide_folding = true
    step_tree_view.connect("item_selected", self, "_on_step_tree_item_selected")
    global.debug_panel.add_section(step_tree_view)

func _draw() -> void:
    var edge_attempt: MovementCalcOverallDebugState = graph.debug_state["edge_calc_debug_state"]
    if edge_attempt != null:
        _draw_step_tree_panel(edge_attempt)

func _draw_step_tree_panel(edge_attempt: MovementCalcOverallDebugState) -> void:
    # Clear any previous items.
    step_tree_view.clear()
    step_tree_root = step_tree_view.create_item()
    
    # Draw rows for each step-attempt.
    for step_attempt in edge_attempt.children_step_attempts:
        _draw_step_tree_item(step_attempt, step_tree_root)

func _draw_step_tree_item(step_attempt: MovementCalcStepDebugState, parent_tree_item: TreeItem) -> void:
    # Draw the row for the given step-attempt.
    var tree_item := step_tree_view.create_item(parent_tree_item)
    var text := _get_tree_item_text(step_attempt, 0, false)
    tree_item.set_text(0, text)
    tree_item_to_step_attempt[tree_item] = step_attempt
    step_attempt_to_tree_items[step_attempt] = [tree_item]
    
    # Recursively draw rows for each child step-attempt.
    for child_step_attempt in step_attempt.children_step_attempts:
        _draw_step_tree_item(child_step_attempt, tree_item)
    
    if step_attempt.description_list.size() > 1:
        # Draw a closing row for the given step-attempt.
        var tree_item_2 := step_tree_view.create_item(parent_tree_item)
        text = _get_tree_item_text(step_attempt, 1, false)
        tree_item_2.set_text(0, text)
        tree_item_to_step_attempt[tree_item_2] = step_attempt
        step_attempt_to_tree_items[step_attempt].push_back(tree_item_2)

func _on_step_tree_item_selected() -> void:
    var selected_tree_item := step_tree_view.get_selected()
    var selected_step_attempt: MovementCalcStepDebugState = \
            tree_item_to_step_attempt[selected_tree_item]
    
    var tree_item: TreeItem
    var old_highlighted_step_attempt: MovementCalcStepDebugState
    var text: String
    
    # Unmark previously matching tree items.
    for i in range(current_highlighted_tree_items.size()):
        tree_item = current_highlighted_tree_items[i]
        old_highlighted_step_attempt = tree_item_to_step_attempt[tree_item]
        text = _get_tree_item_text(old_highlighted_step_attempt, i, false)
        tree_item.set_text(0, text)
    
    current_highlighted_tree_items = step_attempt_to_tree_items[selected_step_attempt]
    
    # Mark all matching tree items.
    for i in range(current_highlighted_tree_items.size()):
        tree_item = current_highlighted_tree_items[i]
        text = _get_tree_item_text(selected_step_attempt, i, true)
        tree_item.set_text(0, text)
    
    emit_signal("step_selected", selected_step_attempt)

func _get_tree_item_text(step_attempt: MovementCalcStepDebugState, description_index: int, \
        includes_highlight_marker: bool) -> String:
    return "%s%s: %s%s%s" % [ \
            "*" if includes_highlight_marker else "",
            step_attempt.index + 1, \
            "[BT] " if step_attempt.is_backtracking and description_index == 0 else "", \
            "[RF] " if step_attempt.replaced_a_fake and description_index == 0 else "", \
            step_attempt.description_list[description_index], \
        ]
