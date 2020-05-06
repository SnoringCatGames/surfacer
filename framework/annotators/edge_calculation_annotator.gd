extends Node2D
class_name EdgeCalculationAnnotator

const STEP_TRANSITION_DELAY_SEC := 1.0

var calculation_selector_annotator: EdgeCalculationSelectorAnnotator
var collision_calculation_annotator: CollisionCalculationAnnotator
var trajectory_annotator: EdgeCalculationTrajectoryAnnotator
var tree_view: EdgeTreeView

var graph: PlatformGraph

var global # TODO: Add type back

var edge_attempt: MovementCalcOverallDebugState

var selected_step: MovementCalcStepDebugState
var is_new_selected_step := false

var start_time: float
var selected_step_transition_index: int = INF
var is_auto_transitioning_with_timer := true

func _init(graph: PlatformGraph) -> void:
    self.graph = graph
    self.calculation_selector_annotator = EdgeCalculationSelectorAnnotator.new()
    self.collision_calculation_annotator = CollisionCalculationAnnotator.new()
    self.trajectory_annotator = EdgeCalculationTrajectoryAnnotator.new()
    self.tree_view = EdgeTreeView.new()

func _enter_tree() -> void:
    add_child(calculation_selector_annotator)
    add_child(trajectory_annotator)
    add_child(collision_calculation_annotator)
    add_child(tree_view)
    
    tree_view.connect( \
            "step_selected", \
            self, \
            "on_step_selected_from_tree_view")

func _ready() -> void:
    global = $"/root/Global"
    start_time = global.elapsed_play_time_sec

func _process(delta: float) -> void:
    # Check the current edge that's being debugged.
    var next_edge_attempt := calculation_selector_annotator.edge_attempt
    var is_new_edge_attempt := next_edge_attempt != edge_attempt
    if is_new_edge_attempt:
        edge_attempt = next_edge_attempt
        
        collision_calculation_annotator.edge_attempt = edge_attempt
        trajectory_annotator.edge_attempt = edge_attempt
        tree_view.edge_attempt = edge_attempt
        
        if edge_attempt != null:
            set_selected_step(_get_step_by_index(edge_attempt, 0))
        else:
            set_selected_step(null)
    
    # Don't try to auto-transition the selected step if there are no steps in the edge attempt.
    if edge_attempt != null and edge_attempt.total_step_count > 0:
        if is_auto_transitioning_with_timer:
            # The selected step is auto-transitioning according to a set time interval.
            var elapsed_time: float = global.elapsed_play_time_sec - start_time
            var next_step_transition_index := \
                    floor(elapsed_time / STEP_TRANSITION_DELAY_SEC) as int % \
                    edge_attempt.total_step_count
            if selected_step_transition_index != next_step_transition_index:
                # We've reached the time to transition to the next selected step.
                selected_step_transition_index = next_step_transition_index
                set_selected_step( \
                        _get_step_by_index( \
                                edge_attempt, \
                                selected_step_transition_index))
                is_new_selected_step = true
    
    if is_new_edge_attempt:
        global.debug_panel.set_is_open(true)
        tree_view.update()
    
    if is_new_selected_step or is_new_edge_attempt:
        # It's time to select a new step, whether from the timer or from a user selection.
        is_new_selected_step = false
        
        trajectory_annotator.update()
        collision_calculation_annotator.update()

func set_selected_step(selected_step: MovementCalcStepDebugState) -> void:
    self.selected_step = selected_step
    collision_calculation_annotator.selected_step = selected_step
    trajectory_annotator.selected_step = selected_step

func on_step_selected_from_tree_view(selected_step_attempt: MovementCalcStepDebugState) -> void:
    is_auto_transitioning_with_timer = false
    is_new_selected_step = true
    set_selected_step(selected_step_attempt)

static func _get_step_by_index( \
        edge_attempt: MovementCalcOverallDebugState, \
        target_step_index: int) -> MovementCalcStepDebugState:
    var result: MovementCalcStepDebugState
    for root_step_attempt in edge_attempt.children_step_attempts:
        result = _get_step_by_index_recursively( \
                root_step_attempt, \
                target_step_index)
        if result != null:
            assert(result.index == target_step_index)
            assert(result.overall_debug_state == edge_attempt)
            return result
    
    return null

static func _get_step_by_index_recursively( \
        step_attempt: MovementCalcStepDebugState, \
        target_step_index: int) -> MovementCalcStepDebugState:
    if step_attempt.index == target_step_index:
        return step_attempt
    
    var result: MovementCalcStepDebugState
    for child_step_attempt in step_attempt.children_step_attempts:
        result = _get_step_by_index_recursively( \
                child_step_attempt, \
                target_step_index)
        if result != null:
            return result
    
    return null
