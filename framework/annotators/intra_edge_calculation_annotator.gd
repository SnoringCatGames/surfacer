extends Node2D
class_name IntraEdgeCalculationAnnotator

const STEP_TRANSITION_DELAY_SEC := 1.0

var collision_calculation_annotator: CollisionCalculationAnnotator
var trajectory_annotator: IntraEdgeCalculationTrajectoryAnnotator
var tree_view_annotator: IntraEdgeCalculationTreeViewAnnotator

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
    self.collision_calculation_annotator = CollisionCalculationAnnotator.new()
    self.trajectory_annotator = IntraEdgeCalculationTrajectoryAnnotator.new()
    self.tree_view_annotator = IntraEdgeCalculationTreeViewAnnotator.new()

func _enter_tree() -> void:
    add_child(collision_calculation_annotator)
    add_child(trajectory_annotator)
    add_child(tree_view_annotator)
    
    tree_view_annotator.connect("step_selected", self, "on_step_selected_from_tree_view")

func _ready() -> void:
    global = $"/root/Global"
    start_time = global.elapsed_play_time_sec

func _process(delta: float) -> void:
    # Check the current edge that's being debugged.
    var next_edge_attempt: MovementCalcOverallDebugState = \
            graph.debug_state["edge_calc_debug_state"]
    var is_new_edge_attempt := next_edge_attempt != edge_attempt
    if is_new_edge_attempt:
        set_edge_attempt(next_edge_attempt)
    
    if edge_attempt == null or edge_attempt.total_step_count == 0:
        # Don't try to draw if we don't currently have an edge to debug.
        return
    
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
                    _get_step_by_index(edge_attempt, selected_step_transition_index))
            is_new_selected_step = true
    
    if is_new_edge_attempt:
        tree_view_annotator.update()
    
    if is_new_selected_step or is_new_edge_attempt:
        # It's time to select a new step, whether from the timer or from a user selection.
        is_new_selected_step = false
        
        collision_calculation_annotator.update()
        trajectory_annotator.update()

func set_edge_attempt(edge_attempt: MovementCalcOverallDebugState) -> void:
    self.edge_attempt = edge_attempt
    collision_calculation_annotator.edge_attempt = edge_attempt
    trajectory_annotator.edge_attempt = edge_attempt
    tree_view_annotator.edge_attempt = edge_attempt

func set_selected_step(selected_step: MovementCalcStepDebugState) -> void:
    self.selected_step = selected_step
    collision_calculation_annotator.selected_step = selected_step
    trajectory_annotator.selected_step = selected_step

func on_step_selected_from_tree_view(selected_step_attempt: MovementCalcStepDebugState) -> void:
    is_auto_transitioning_with_timer = false
    is_new_selected_step = true
    set_selected_step(selected_step_attempt)
    collision_calculation_annotator.on_step_selected(selected_step_attempt)
    trajectory_annotator.on_step_selected(selected_step_attempt)

static func _get_step_by_index(edge_attempt: MovementCalcOverallDebugState, \
        target_step_index: int) -> MovementCalcStepDebugState:
    var result: MovementCalcStepDebugState
    for root_step_attempt in edge_attempt.children_step_attempts:
        result = _get_step_by_index_recursively(root_step_attempt, target_step_index)
        if result != null:
            assert(result.index == target_step_index)
            assert(result.overall_debug_state == edge_attempt)
            return result
    
    return null

static func _get_step_by_index_recursively(step_attempt: MovementCalcStepDebugState, \
        target_step_index: int) -> MovementCalcStepDebugState:
    if step_attempt.index == target_step_index:
        return step_attempt
    
    var result: MovementCalcStepDebugState
    for child_step_attempt in step_attempt.children_step_attempts:
        result = _get_step_by_index_recursively(child_step_attempt, target_step_index)
        if result != null:
            return result
    
    return null
