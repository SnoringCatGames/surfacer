extends Node2D
class_name IntraEdgeCalculationAnnotator

const STEP_TRANSITION_DELAY_SEC := 1.0

const TRAJECTORY_WIDTH := 1.0
const COLLISION_X_WIDTH_HEIGHT := Vector2(16.0, 16.0)
const COLLISION_X_STROKE_WIDTH := 3.0
const COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH := 1.0
const CONSTRAINT_WIDTH := 2.0
const CONSTRAINT_RADIUS := 3.0 * CONSTRAINT_WIDTH
const LABEL_SCALE := Vector2(2.0, 2.0)
const LABEL_OFFSET := Vector2(15.0, -10.0)

const STEP_HUE_START := 0.11
const STEP_HUE_END := 0.61
const COLLISION_HUE := 0.0
const FAINT_OPACITY := 0.2
const STRONG_OPACITY := 0.9

var collision_color_faint := Color.from_hsv(COLLISION_HUE, 0.6, 0.9, FAINT_OPACITY)
var collision_color_strong := Color.from_hsv(COLLISION_HUE, 0.6, 0.9, STRONG_OPACITY)

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
    var step_attempts: Array
    var step_attempts_count: int
    var step_attempt: MovementCalcStepDebugState
    var step_index: int
    
    var edge_calc_debug_state = graph.debug_state["edge_calc_debug_state"]
    if edge_calc_debug_state != null:
        # Iterate over all edge calculations.
        for edge_attempt in edge_calc_debug_state:
            step_attempts = edge_attempt.step_attempts
            step_attempts_count = step_attempts.size()
            
            # Render faintly all calculation steps for this edge.
            for step_index in range(step_attempts_count):
                step_attempt = step_attempts[step_index]
                _render_step(edge_attempt, step_attempt, step_index, step_attempts_count, true)
            
            # Render with more opacity the current step.
            step_index = step_transition_index % step_attempts_count
            step_attempt = step_attempts[step_index]
            _render_step(edge_attempt, step_attempt, step_index, step_attempts_count, false)

func _render_step(edge_attempt: MovementCalcOverallDebugState, \
        step_attempt: MovementCalcStepDebugState, step_index: int, step_attempts_count: int, \
        renders_faintly: bool) -> void:
    # Hue transitions evenly from start to end.
    var step_hue := STEP_HUE_START + \
            (STEP_HUE_END - STEP_HUE_START) * (step_index / (step_attempts_count - 1.0))
    var step_opactity := FAINT_OPACITY if renders_faintly else STRONG_OPACITY
    var step_color := Color.from_hsv(step_hue, 0.6, 0.9, step_opactity)
    
    # Draw the step trajectory.
    draw_polyline(step_attempt.frame_positions, step_color, TRAJECTORY_WIDTH)
    
    # Draw the step end points.
    DrawUtils.draw_circle_outline(self, step_attempt.start_constraint.position, \
            CONSTRAINT_RADIUS, step_color, CONSTRAINT_WIDTH, 4.0)
    DrawUtils.draw_circle_outline(self, step_attempt.end_constraint.position, \
            CONSTRAINT_RADIUS, step_color, CONSTRAINT_WIDTH, 4.0)
    
    var collision := step_attempt.collision
    
    # Draw any collision.
    if collision != null:
        var collision_color := collision_color_faint if renders_faintly else collision_color_strong
        
        # Draw an X at the actual point of collision.
        DrawUtils.draw_x(self, collision.position, COLLISION_X_WIDTH_HEIGHT.x, \
                COLLISION_X_WIDTH_HEIGHT.y, collision_color, COLLISION_X_STROKE_WIDTH)
        
        # Draw an outline of the player's collision boundary at the point of collision.
        DrawUtils.draw_shape_outline(self, collision.player_position, \
                edge_attempt.movement_params.collider_shape, \
                edge_attempt.movement_params.collider_rotation, collision_color, \
                COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH)
    
    # Draw some text describing the current step.
    label.rect_position = step_attempt.start_constraint.position + LABEL_OFFSET
    label.add_color_override("font_color", step_color)
    label.text = "Step %s/%s: [%s] %s" % [step_index + 1, step_attempts_count, \
            step_attempt.result_code_string, step_attempt.description]
