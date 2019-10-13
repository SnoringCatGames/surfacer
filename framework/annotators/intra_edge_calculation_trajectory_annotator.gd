extends Node2D
class_name IntraEdgeCalculationTrajectoryAnnotator

const STEP_TRANSITION_DELAY_SEC := 1.0

const COLLISION_X_WIDTH_HEIGHT := Vector2(16.0, 16.0)
const COLLISION_PLAYER_BOUNDARY_CENTER_RADIUS := 3.0
const CONSTRAINT_RADIUS := 6.0

const LABEL_SCALE := Vector2(2.0, 2.0)
const LABEL_OFFSET := Vector2(15.0, -10.0)

const TRAJECTORY_STROKE_WIDTH_FAINT := 1.0
const TRAJECTORY_STROKE_WIDTH_STRONG := 3.0
const CONSTRAINT_STROKE_WIDTH_FAINT := CONSTRAINT_RADIUS / 3.0
const CONSTRAINT_STROKE_WIDTH_STRONG := CONSTRAINT_STROKE_WIDTH_FAINT * 2.0
const COLLISION_X_STROKE_WIDTH_FAINT := 2.0
const COLLISION_X_STROKE_WIDTH_STRONG := 5.0
const COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_FAINT := 1.0
const COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_STRONG := 3.0

const STEP_HUE_START := 0.11
const STEP_HUE_END := 0.61
const COLLISION_HUE := 0.0

const OPACITY_FAINT := 0.2
const OPACITY_STRONG := 0.9

var collision_color_faint := Color.from_hsv(COLLISION_HUE, 0.6, 0.9, OPACITY_FAINT)
var collision_color_strong := Color.from_hsv(COLLISION_HUE, 0.6, 0.9, OPACITY_STRONG)

var global # TODO: Add type back

var graph: PlatformGraph
var edge_attempt: MovementCalcOverallDebugState

var label: Label

var highlighted_step: MovementCalcStepDebugState
var is_new_highlighted_step := false

var start_time: float
var highlighted_step_transition_index: int = INF
var is_auto_transitioning_with_timer := true

func _init(graph: PlatformGraph) -> void:
    self.graph = graph

func _ready() -> void:
    global = $"/root/Global"
    start_time = global.elapsed_play_time_sec
    
    label = Label.new()
    label.rect_scale = LABEL_SCALE
    add_child(label)

func _process(delta: float) -> void:
    # Check the current edge that's being debugged.
    var next_edge_attempt: MovementCalcOverallDebugState = \
            graph.debug_state["edge_calc_debug_state"]
    var is_new_edge_attempt := next_edge_attempt != edge_attempt
    if is_new_edge_attempt:
        edge_attempt = next_edge_attempt
    
    if edge_attempt == null:
        # Don't try to draw if we don't currently have an edge to debug.
        return
    
    if is_auto_transitioning_with_timer:
        # The highlighted step is auto-transitioning according to a set time interval.
        var elapsed_time: float = global.elapsed_play_time_sec - start_time
        var next_step_transition_index := \
                floor(elapsed_time / STEP_TRANSITION_DELAY_SEC) as int % \
                edge_attempt.total_step_count
        if highlighted_step_transition_index != next_step_transition_index:
            # We've reached the time to transition to the next highlighted step.
            highlighted_step_transition_index = next_step_transition_index
            highlighted_step = _get_step_by_index(highlighted_step_transition_index)
            is_new_highlighted_step = true
    
    if is_new_highlighted_step or is_new_edge_attempt:
        # It's time to highlight a new step, whether from the timer or from a user selection.
        update()

func _get_step_by_index(target_step_index: int) -> MovementCalcStepDebugState:
    var result: MovementCalcStepDebugState
    for root_step_attempt in edge_attempt.children_step_attempts:
        result = _get_step_by_index_recursively(root_step_attempt, target_step_index)
        if result != null:
            assert(result.index == target_step_index)
            assert(result.overall_debug_state == edge_attempt)
            return result
    
    return null

func _get_step_by_index_recursively(step_attempt: MovementCalcStepDebugState, \
        target_step_index: int) -> MovementCalcStepDebugState:
    if step_attempt.index == target_step_index:
        return step_attempt
    
    var result: MovementCalcStepDebugState
    for child_step_attempt in step_attempt.children_step_attempts:
        result = _get_step_by_index_recursively(child_step_attempt, target_step_index)
        if result != null:
            return result
    
    return null

func _draw() -> void:
    if edge_attempt == null:
        # Don't try to draw if we don't currently have an edge to debug.
        return
    
    _draw_edge_calculation_trajectories()

func _draw_edge_calculation_trajectories() -> void:
    var next_step_index := 0
    
    # Render faintly all calculation steps for this edge.
    for root_step in edge_attempt.children_step_attempts:
        next_step_index = _draw_steps_recursively(root_step, next_step_index)
    
    # Render with more opacity the current step.
    _draw_step(highlighted_step, false)

func _draw_steps_recursively( \
        step_attempt: MovementCalcStepDebugState, next_step_index: int) -> int:
    assert(step_attempt.index == next_step_index)
    assert(step_attempt.overall_debug_state == edge_attempt)
    _draw_step(step_attempt, true)
    
    next_step_index += 1
    
    for child_step_attempt in step_attempt.children_step_attempts:
        next_step_index = _draw_steps_recursively(child_step_attempt, next_step_index)
    
    return next_step_index

func _draw_step(step_attempt: MovementCalcStepDebugState, renders_faintly: bool) -> void:
    var edge_attempt: MovementCalcOverallDebugState = step_attempt.overall_debug_state
    
    var step_opactity: float
    var trajectory_stroke_width: float
    var constraint_stroke_width: float
    var collision_color: Color
    var collision_x_stroke_width: float
    var collision_player_boundary_stroke_width: float
    if renders_faintly:
        step_opactity = OPACITY_FAINT
        trajectory_stroke_width = TRAJECTORY_STROKE_WIDTH_FAINT
        constraint_stroke_width = CONSTRAINT_STROKE_WIDTH_FAINT
        collision_color = collision_color_faint
        collision_x_stroke_width = COLLISION_X_STROKE_WIDTH_FAINT
        collision_player_boundary_stroke_width = COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_FAINT
    else:
        step_opactity = OPACITY_STRONG
        trajectory_stroke_width = TRAJECTORY_STROKE_WIDTH_STRONG
        constraint_stroke_width = CONSTRAINT_STROKE_WIDTH_STRONG
        collision_color = collision_color_strong
        collision_x_stroke_width = COLLISION_X_STROKE_WIDTH_STRONG
        collision_player_boundary_stroke_width = COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_STRONG
    
    # Hue transitions evenly from start to end.
    var step_hue := STEP_HUE_START + (STEP_HUE_END - STEP_HUE_START) * (step_attempt.index / \
            (edge_attempt.total_step_count - 1.0))
    var step_color := Color.from_hsv(step_hue, 0.6, 0.9, step_opactity)
    
    # Draw the step trajectory.
    draw_polyline(step_attempt.frame_positions, step_color, trajectory_stroke_width)
    
    # Draw the step end points.
    DrawUtils.draw_circle_outline(self, step_attempt.start_constraint.position, \
            CONSTRAINT_RADIUS, step_color, constraint_stroke_width, 4.0)
    DrawUtils.draw_circle_outline(self, step_attempt.end_constraint.position, \
            CONSTRAINT_RADIUS, step_color, constraint_stroke_width, 4.0)
    
    var collision := step_attempt.collision
    
    # Draw any collision.
    if collision != null:
        # Draw an X at the actual point of collision.
        DrawUtils.draw_x(self, collision.position, COLLISION_X_WIDTH_HEIGHT.x, \
                COLLISION_X_WIDTH_HEIGHT.y, collision_color, collision_x_stroke_width)
        
        # Draw an outline of the player's collision boundary at the point of collision.
        DrawUtils.draw_shape_outline(self, collision.player_position, \
                edge_attempt.movement_params.collider_shape, \
                edge_attempt.movement_params.collider_rotation, collision_color, \
                collision_player_boundary_stroke_width)
        # Draw a dot at the center of the player's collision boundary.
        draw_circle(collision.player_position, COLLISION_PLAYER_BOUNDARY_CENTER_RADIUS, \
                collision_color)
    
    # Draw some text describing the current step.
    label.rect_position = step_attempt.start_constraint.position + LABEL_OFFSET
    label.add_color_override("font_color", step_color)
    label.text = "Step %s/%s: [%s] %s" % [step_attempt.index + 1, edge_attempt.total_step_count, \
            step_attempt.result_code_string, step_attempt.description]

func on_step_selected(selected_step_attempt: MovementCalcStepDebugState) -> void:
    is_auto_transitioning_with_timer = false
    is_new_highlighted_step = true
    highlighted_step = selected_step_attempt
