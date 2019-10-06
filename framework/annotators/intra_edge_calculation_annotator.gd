extends Node2D
class_name IntraEdgeCalculationAnnotator

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
var label: Label

var start_time: float
var step_transition_index: int

func _init(graph: PlatformGraph) -> void:
    self.graph = graph

func _ready() -> void:
    global = $"/root/Global"
    start_time = global.elapsed_play_time_sec
    
    label = Label.new()
    label.rect_scale = LABEL_SCALE
    add_child(label)

func _process(delta: float) -> void:
    var elapsed_time: float = global.elapsed_play_time_sec - start_time
    var next_step_transition_index: int = floor(elapsed_time / STEP_TRANSITION_DELAY_SEC)
    
    if step_transition_index != next_step_transition_index:
        step_transition_index = next_step_transition_index
        update()

func _draw() -> void:
    var edge_attempts: Array = graph.debug_state["edge_calc_debug_state"]
    if edge_attempts != null:
        _draw_edge_calculation_trajectories(edge_attempts)
        _draw_step_tree_panel(edge_attempts)

func _draw_edge_calculation_trajectories(edge_attempts: Array) -> void:
    var step_attempts: Array
    var step_attempts_count: int
    var step_attempt: MovementCalcStepDebugState
    var step_index: int
    
    # Iterate over all edge calculations.
    for edge_attempt in edge_attempts:
        step_attempts = edge_attempt.children_step_attempts
        step_attempts_count = step_attempts.size()
        
        # Render faintly all calculation steps for this edge.
        for step_index in range(step_attempts_count):
            step_attempt = step_attempts[step_index]
            _draw_step(edge_attempt, step_attempt, step_index, step_attempts_count, true)
        
        # Render with more opacity the current step.
        step_index = step_transition_index % step_attempts_count
        step_attempt = step_attempts[step_index]
        _draw_step(edge_attempt, step_attempt, step_index, step_attempts_count, false)

func _draw_step(edge_attempt: MovementCalcOverallDebugState, \
        step_attempt: MovementCalcStepDebugState, step_index: int, step_attempts_count: int, \
        renders_faintly: bool) -> void:
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
    var step_hue := STEP_HUE_START + \
            (STEP_HUE_END - STEP_HUE_START) * (step_index / (step_attempts_count - 1.0))
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
    label.text = "Step %s/%s: [%s] %s" % [step_index + 1, step_attempts_count, \
            step_attempt.result_code_string, step_attempt.description]

func _draw_step_tree_panel(edge_attempts: Array) -> void:
    # Iterate over all edge calculations.
    for edge_attempt in edge_attempts:
        # Draw rows for each step-attempt.
        for step_attempt in edge_attempt.children_step_attempts:
            _draw_step_tree_item(step_attempt, 0)

func _draw_step_tree_item( \
        step_attempt: MovementCalcStepDebugState, indentation_level: int) -> void:
    # Draw the row for the given step-attempt.
    # FIXME: LEFT OFF HERE: ----------------------------------------------------A
    # - Use VBoxContainer?
    
    # Recursively draw rows for each child step-attempt.
    for child_step_attempt in step_attempt.children_step_attempts:
        _draw_step_tree_item(child_step_attempt, indentation_level + 1)
