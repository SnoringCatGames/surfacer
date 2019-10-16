extends Node2D
class_name IntraEdgeCalculationTreeViewAnnotator

signal step_selected

var global # TODO: Add type back
var graph: PlatformGraph
var step_tree_view: Tree
var step_tree_root: TreeItem

# Dictionary<TreeItem, MovementCalcStepDebugState>
const tree_item_to_step_attempt := {}

func _init(graph: PlatformGraph) -> void:
    self.graph = graph

func _ready() -> void:
    global = $"/root/Global"
    
    step_tree_view = Tree.new()
    step_tree_view.rect_min_size = Vector2(0.0, 280.0)
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
    
    var next_index := 0
    
    # Draw rows for each step-attempt.
    for step_attempt in edge_attempt.children_step_attempts:
        next_index = _draw_step_tree_item(step_attempt, step_tree_root, next_index)

func _draw_step_tree_item(step_attempt: MovementCalcStepDebugState, parent_tree_item: TreeItem, \
        next_index: int) -> int:
    assert(next_index == step_attempt.index)# FIXME: REMOVE
    # Draw the row for the given step-attempt.
    var tree_item := step_tree_view.create_item(parent_tree_item)
    var text := "%s: %s" % [next_index + 1, step_attempt.result_code_string]
    tree_item.set_text(0, text)
    tree_item_to_step_attempt[tree_item] = step_attempt
    
    next_index += 1
    
    # Recursively draw rows for each child step-attempt.
    for child_step_attempt in step_attempt.children_step_attempts:
        next_index = _draw_step_tree_item(child_step_attempt, tree_item, next_index)
    
    return next_index

func _on_step_tree_item_selected() -> void:
    var selected_tree_item := step_tree_view.get_selected()
    var selected_step_attempt: MovementCalcStepDebugState = \
            tree_item_to_step_attempt[selected_tree_item]
    emit_signal("step_selected", selected_step_attempt)
