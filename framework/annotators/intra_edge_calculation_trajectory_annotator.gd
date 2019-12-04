extends Node2D
class_name IntraEdgeCalculationTrajectoryAnnotator

const STEP_TRANSITION_DELAY_SEC := 1.0

const COLLISION_X_WIDTH_HEIGHT := Vector2(16.0, 16.0)
const COLLISION_PLAYER_BOUNDARY_CENTER_RADIUS := 3.0
const CONSTRAINT_RADIUS := 6.0
const VALID_CONSTRAINT_WIDTH := 16.0
const INVALID_CONSTRAINT_WIDTH := 12.0
const INVALID_CONSTRAINT_HEIGHT := 16.0
const PREVIOUS_OUT_OF_REACH_CONSTRAINT_WIDTH_HEIGHT := 15.0

const STEP_LABEL_SCALE := Vector2(2.0, 2.0)
const PREVIOUS_OUT_OF_REACH_CONSTRAINT_LABEL_SCALE := Vector2(1.4, 1.4)
const LABEL_OFFSET := Vector2(15.0, -10.0)

const TRAJECTORY_STROKE_WIDTH_FAINT := 1.0
const TRAJECTORY_STROKE_WIDTH_STRONG := 3.0
const CONSTRAINT_STROKE_WIDTH_FAINT := CONSTRAINT_RADIUS / 3.0
const CONSTRAINT_STROKE_WIDTH_STRONG := CONSTRAINT_STROKE_WIDTH_FAINT * 2.0
const COLLISION_X_STROKE_WIDTH_FAINT := 2.0
const COLLISION_X_STROKE_WIDTH_STRONG := 5.0
const COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_FAINT := 1.0
const COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_STRONG := 3.0
const VALID_CONSTRAINT_STROKE_WIDTH := 2.0
const INVALID_CONSTRAINT_STROKE_WIDTH := 2.0

const TRAJECTORY_DASH_LENGTH := 2.0
const TRAJECTORY_DASH_GAP := 8.0

const STEP_HUE_START := 0.11
const STEP_HUE_END := 0.61
const COLLISION_HUE := 0.0

const OPACITY_FAINT := 0.2
const OPACITY_STRONG := 0.9

var collision_color_faint := Color.from_hsv(COLLISION_HUE, 0.6, 0.9, OPACITY_FAINT)
var collision_color_strong := Color.from_hsv(COLLISION_HUE, 0.6, 0.9, OPACITY_STRONG)

var edge_attempt: MovementCalcOverallDebugState
var selected_step: MovementCalcStepDebugState

var step_label: Label
var previous_out_of_reach_constraint_label: Label

func _ready() -> void:
    step_label = Label.new()
    step_label.rect_scale = STEP_LABEL_SCALE
    add_child(step_label)
    
    previous_out_of_reach_constraint_label = Label.new()
    previous_out_of_reach_constraint_label.rect_scale = \
            PREVIOUS_OUT_OF_REACH_CONSTRAINT_LABEL_SCALE
    add_child(previous_out_of_reach_constraint_label)

func _draw() -> void:
    if edge_attempt == null or edge_attempt.total_step_count == 0:
        # Don't try to draw if we don't currently have an edge to debug.
        return
    
    _draw_edge_calculation_trajectories()

func _draw_edge_calculation_trajectories() -> void:
    var next_step_index := 0
    
    # Render faintly all calculation steps for this edge.
    for root_step in edge_attempt.children_step_attempts:
        next_step_index = _draw_steps_recursively(root_step, next_step_index)
    
    # Render with more opacity the current step.
    _draw_step(selected_step, false)

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
    
    var step_opacity: float
    var trajectory_stroke_width: float
    var constraint_stroke_width: float
    var collision_color: Color
    var collision_x_stroke_width: float
    var collision_player_boundary_stroke_width: float
    if renders_faintly:
        step_opacity = OPACITY_FAINT
        trajectory_stroke_width = TRAJECTORY_STROKE_WIDTH_FAINT
        constraint_stroke_width = CONSTRAINT_STROKE_WIDTH_FAINT
        collision_color = collision_color_faint
        collision_x_stroke_width = COLLISION_X_STROKE_WIDTH_FAINT
        collision_player_boundary_stroke_width = COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_FAINT
    else:
        step_opacity = OPACITY_STRONG
        trajectory_stroke_width = TRAJECTORY_STROKE_WIDTH_STRONG
        constraint_stroke_width = CONSTRAINT_STROKE_WIDTH_STRONG
        collision_color = collision_color_strong
        collision_x_stroke_width = COLLISION_X_STROKE_WIDTH_STRONG
        collision_player_boundary_stroke_width = COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_STRONG
    
    # Hue transitions evenly from start to end.
    var step_ratio := (step_attempt.index / (edge_attempt.total_step_count - 1.0)) if \
            edge_attempt.total_step_count > 1 else 1.0
    var step_hue := STEP_HUE_START + (STEP_HUE_END - STEP_HUE_START) * step_ratio
    var step_color := Color.from_hsv(step_hue, 0.6, 0.9, step_opacity)
    
    if step_attempt.frame_positions.size() > 1:
        # Draw the step trajectory.
        DrawUtils.draw_dashed_polyline(self, step_attempt.frame_positions, step_color, \
                TRAJECTORY_DASH_LENGTH, TRAJECTORY_DASH_GAP, 0.0, trajectory_stroke_width)
    
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
        
        if !renders_faintly:
            # Draw the surface that was collided with.
            DrawUtils.draw_surface(self, collision.surface, collision_color)
        
        # Draw an outline of the player's collision boundary at the point of collision.
        DrawUtils.draw_shape_outline(self, collision.player_position, \
                edge_attempt.movement_params.collider_shape, \
                edge_attempt.movement_params.collider_rotation, collision_color, \
                collision_player_boundary_stroke_width)
        # Draw a dot at the center of the player's collision boundary.
        draw_circle(collision.player_position, COLLISION_PLAYER_BOUNDARY_CENTER_RADIUS, \
                collision_color)
        
        if !renders_faintly:
            # Draw the upcoming constraints, around the collision.
            for upcoming_constraint in step_attempt.upcoming_constraints:
                if upcoming_constraint.is_valid:
                    DrawUtils.draw_checkmark(self, upcoming_constraint.position, \
                            VALID_CONSTRAINT_WIDTH, step_color, VALID_CONSTRAINT_STROKE_WIDTH)
                else:
                    DrawUtils.draw_x(self, upcoming_constraint.position, \
                            INVALID_CONSTRAINT_WIDTH, INVALID_CONSTRAINT_HEIGHT, step_color, \
                            INVALID_CONSTRAINT_STROKE_WIDTH)
    
    # For new backtracking steps, draw and label the constraint that was used as the basis for a
    # higher jump.
    if step_attempt.is_backtracking and !renders_faintly:
        # Draw the constraint position.
        DrawUtils.draw_diamond_outline(self, \
                step_attempt.previous_out_of_reach_constraint.position, \
                PREVIOUS_OUT_OF_REACH_CONSTRAINT_WIDTH_HEIGHT, \
                PREVIOUS_OUT_OF_REACH_CONSTRAINT_WIDTH_HEIGHT, step_color, 1.0)
        
        # Label the constraint.
        previous_out_of_reach_constraint_label.rect_position = \
                step_attempt.previous_out_of_reach_constraint.position + LABEL_OFFSET
        previous_out_of_reach_constraint_label.add_color_override("font_color", step_color)
        previous_out_of_reach_constraint_label.text = \
                "The previously out-of-reach constraint that was the basis\n" + \
                "for increasing the jump height for backtracking."
    else:
        previous_out_of_reach_constraint_label.text = ""
    
    # Draw some text describing the current step.
    step_label.rect_position = step_attempt.start_constraint.position + LABEL_OFFSET
    step_label.add_color_override("font_color", step_color)
    var line_1 := "Step %s/%s: %s" % [step_attempt.index + 1, edge_attempt.total_step_count, \
            step_attempt.result_code_string]
    var line_2 := "\n                [Backtracking]" if step_attempt.is_backtracking else ""
    var line_3 := "\n                [Replaced fake constraint]" if \
            step_attempt.replaced_a_fake else ""
    var line_4: String = "\n                %s" % step_attempt.description_list[0]
    var line_5: String = ("\n                %s" % step_attempt.description_list[1]) if \
            step_attempt.description_list.size() > 1 else ""
    step_label.text = line_1 + line_2 + line_3 + line_4 + line_5

func on_step_selected(selected_step_attempt: MovementCalcStepDebugState) -> void:
    self.selected_step = selected_step_attempt
