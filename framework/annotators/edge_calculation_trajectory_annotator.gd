extends Node2D
class_name EdgeCalculationTrajectoryAnnotator

# FIXME: LEFT OFF HERE: -----------------------------------

const STEP_TRANSITION_DELAY_SEC := 1.0

const COLLISION_X_WIDTH_HEIGHT := Vector2(16.0, 16.0)
const COLLISION_PLAYER_BOUNDARY_CENTER_RADIUS := 3.0
const WAYPOINT_RADIUS := 6.0
const VALID_WAYPOINT_WIDTH := 16.0
const INVALID_WAYPOINT_WIDTH := 12.0
const INVALID_WAYPOINT_HEIGHT := 16.0
const PREVIOUS_OUT_OF_REACH_WAYPOINT_WIDTH_HEIGHT := 15.0

const STEP_LABEL_SCALE := Vector2(2.0, 2.0)
const PREVIOUS_OUT_OF_REACH_WAYPOINT_LABEL_SCALE := Vector2(1.4, 1.4)
const LABEL_OFFSET := Vector2(15.0, -10.0)

const TRAJECTORY_STROKE_WIDTH_FAINT := 1.0
const TRAJECTORY_STROKE_WIDTH_STRONG := 3.0
const WAYPOINT_STROKE_WIDTH_FAINT := WAYPOINT_RADIUS / 3.0
const WAYPOINT_STROKE_WIDTH_STRONG := WAYPOINT_STROKE_WIDTH_FAINT * 2.0
const COLLISION_X_STROKE_WIDTH_FAINT := 2.0
const COLLISION_X_STROKE_WIDTH_STRONG := 5.0
const COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_FAINT := 1.0
const COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_STRONG := 3.0
const VALID_WAYPOINT_STROKE_WIDTH := 2.0
const INVALID_WAYPOINT_STROKE_WIDTH := 2.0

const TRAJECTORY_DASH_LENGTH := 2.0
const TRAJECTORY_DASH_GAP := 8.0

const INVALID_EDGE_DASH_LENGTH := 6.0
const INVALID_EDGE_DASH_GAP := 8.0
const INVALID_EDGE_DASH_STROKE_WIDTH := 4.0
const INVALID_EDGE_X_WIDTH := 20.0
const INVALID_EDGE_X_HEIGHT := 28.0

const STEP_HUE_START := 0.11
const STEP_HUE_END := 0.61
const COLLISION_HUE := 0.0

const OPACITY_FAINT := 0.2
const OPACITY_STRONG := 0.9

var collision_color_faint := Color.from_hsv( \
        COLLISION_HUE, \
        0.6, \
        0.9, \
        OPACITY_FAINT)
var collision_color_strong := Color.from_hsv( \
        COLLISION_HUE, \
        0.6, \
        0.9, \
        OPACITY_STRONG)
var INVALID_EDGE_COLOR := Color.from_hsv( \
        COLLISION_HUE, \
        0.6, \
        0.9, \
        OPACITY_STRONG)

# FIXME: --------------- Remove?
const INVALID_EDGE_TEXT := "Unable to reach destination from origin."

#var edge_attempt: MovementCalcOverallDebugState
#var selected_step: MovementCalcStepDebugState
#
#var step_label: Label
#var previous_out_of_reach_waypoint_label: Label
#
#func _ready() -> void:
#    step_label = Label.new()
#    step_label.rect_scale = STEP_LABEL_SCALE
#    add_child(step_label)
#
#    previous_out_of_reach_waypoint_label = Label.new()
#    previous_out_of_reach_waypoint_label.rect_scale = \
#            PREVIOUS_OUT_OF_REACH_WAYPOINT_LABEL_SCALE
#    add_child(previous_out_of_reach_waypoint_label)
#
#func _draw() -> void:
#    step_label.text = ""
#    previous_out_of_reach_waypoint_label.text = ""
#
#    if edge_attempt == null:
#        # Don't try to draw if we don't currently have an edge to debug.
#        return
#
#    if edge_attempt.failed_before_creating_steps:
#        _draw_invalid_edge()
#    else:
#        _draw_edge_calculation_trajectories()
#
#func _draw_edge_calculation_trajectories() -> void:
#    var next_step_index := 0
#
#    # Render faintly all calculation steps for this edge.
#    for root_step in edge_attempt.children_step_attempts:
#        next_step_index = _draw_steps_recursively(root_step, next_step_index)
#
#    # Render with more opacity the current step.
#    _draw_step(selected_step, false)
#
#func _draw_steps_recursively( \
#        step_attempt: MovementCalcStepDebugState, \
#        next_step_index: int) -> int:
#    assert(step_attempt.index == next_step_index)
#    assert(step_attempt.overall_debug_state == edge_attempt)
#    _draw_step(step_attempt, true)
#
#    next_step_index += 1
#
#    for child_step_attempt in step_attempt.children_step_attempts:
#        next_step_index = _draw_steps_recursively(child_step_attempt, next_step_index)
#
#    return next_step_index
#
#func _draw_step( \
#        step_attempt: MovementCalcStepDebugState, \
#        renders_faintly: bool) -> void:
#    var edge_attempt: MovementCalcOverallDebugState = step_attempt.overall_debug_state
#
#    var step_opacity: float
#    var trajectory_stroke_width: float
#    var waypoint_stroke_width: float
#    var collision_color: Color
#    var collision_x_stroke_width: float
#    var collision_player_boundary_stroke_width: float
#    if renders_faintly:
#        step_opacity = OPACITY_FAINT
#        trajectory_stroke_width = TRAJECTORY_STROKE_WIDTH_FAINT
#        waypoint_stroke_width = WAYPOINT_STROKE_WIDTH_FAINT
#        collision_color = collision_color_faint
#        collision_x_stroke_width = COLLISION_X_STROKE_WIDTH_FAINT
#        collision_player_boundary_stroke_width = COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_FAINT
#    else:
#        step_opacity = OPACITY_STRONG
#        trajectory_stroke_width = TRAJECTORY_STROKE_WIDTH_STRONG
#        waypoint_stroke_width = WAYPOINT_STROKE_WIDTH_STRONG
#        collision_color = collision_color_strong
#        collision_x_stroke_width = COLLISION_X_STROKE_WIDTH_STRONG
#        collision_player_boundary_stroke_width = COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH_STRONG
#
#    # Hue transitions evenly from start to end.
#    var step_ratio := (step_attempt.index / (edge_attempt.total_step_count - 1.0)) if \
#            edge_attempt.total_step_count > 1 else 1.0
#    var step_hue := STEP_HUE_START + (STEP_HUE_END - STEP_HUE_START) * step_ratio
#    var step_color := Color.from_hsv( \
#            step_hue, \
#            0.6, \
#            0.9, \
#            step_opacity)
#
#    if step_attempt.step != null and step_attempt.step.frame_positions.size() > 1:
#        # Draw the step trajectory.
#        DrawUtils.draw_dashed_polyline( \
#                self, \
#                PoolVector2Array(step_attempt.step.frame_positions), \
#                step_color, \
#                TRAJECTORY_DASH_LENGTH, \
#                TRAJECTORY_DASH_GAP, \
#                0.0, \
#                trajectory_stroke_width)
#    else:
#        # The calculation failed before a step object could be created.
#        _draw_invalid_trajectory( \
#                step_attempt.start_waypoint.position, \
#                step_attempt.end_waypoint.position)
#
#    # Draw the step end points.
#    DrawUtils.draw_circle_outline( \
#            self, \
#            step_attempt.start_waypoint.position, \
#            WAYPOINT_RADIUS, \
#            step_color, \
#            waypoint_stroke_width, \
#            4.0)
#    DrawUtils.draw_circle_outline( \
#            self, \
#            step_attempt.end_waypoint.position, \
#            WAYPOINT_RADIUS, \
#            step_color, \
#            waypoint_stroke_width, \
#            4.0)
#
#    var collision := step_attempt.collision
#
#    # Draw any collision.
#    if collision != null:
#        if collision.position != Vector2.INF:
#            # Draw an X at the actual point of collision.
#            DrawUtils.draw_x( \
#                    self, \
#                    collision.position, \
#                    COLLISION_X_WIDTH_HEIGHT.x, \
#                    COLLISION_X_WIDTH_HEIGHT.y, \
#                    collision_color, \
#                    collision_x_stroke_width)
#
#        if !renders_faintly and collision.surface != null:
#            # Draw the surface that was collided with.
#            DrawUtils.draw_surface( \
#                    self, \
#                    collision.surface, \
#                    collision_color)
#
#        # Draw an outline of the player's collision boundary at the point of collision.
#        DrawUtils.draw_shape_outline( \
#                self, \
#                collision.player_position, \
#                edge_attempt.movement_params.collider_shape, \
#                edge_attempt.movement_params.collider_rotation, \
#                collision_color, \
#                collision_player_boundary_stroke_width)
#        # Draw a dot at the center of the player's collision boundary.
#        draw_circle( \
#                collision.player_position, \
#                COLLISION_PLAYER_BOUNDARY_CENTER_RADIUS, \
#                collision_color)
#
#        if !renders_faintly:
#            # Draw the upcoming waypoints, around the collision.
#            for upcoming_waypoint in step_attempt.upcoming_waypoints:
#                if upcoming_waypoint.is_valid:
#                    DrawUtils.draw_checkmark( \
#                            self, \
#                            upcoming_waypoint.position, \
#                            VALID_WAYPOINT_WIDTH, \
#                            step_color, \
#                            VALID_WAYPOINT_STROKE_WIDTH)
#                else:
#                    DrawUtils.draw_x( \
#                            self, \
#                            upcoming_waypoint.position, \
#                            INVALID_WAYPOINT_WIDTH, \
#                            INVALID_WAYPOINT_HEIGHT, \
#                            step_color, \
#                            INVALID_WAYPOINT_STROKE_WIDTH)
#
#    # For new backtracking steps, draw and label the waypoint that was used as the basis for a
#    # higher jump.
#    if step_attempt.is_backtracking and !renders_faintly:
#        # Draw the waypoint position.
#        DrawUtils.draw_diamond_outline( \
#                self, \
#                step_attempt.previous_out_of_reach_waypoint.position, \
#                PREVIOUS_OUT_OF_REACH_WAYPOINT_WIDTH_HEIGHT, \
#                PREVIOUS_OUT_OF_REACH_WAYPOINT_WIDTH_HEIGHT, \
#                step_color, \
#                1.0)
#
#        # Label the waypoint.
#        previous_out_of_reach_waypoint_label.rect_position = \
#                step_attempt.previous_out_of_reach_waypoint.position + LABEL_OFFSET
#        previous_out_of_reach_waypoint_label.add_color_override("font_color", step_color)
#        previous_out_of_reach_waypoint_label.text = \
#                "The previously out-of-reach waypoint that was the basis\n" + \
#                "for increasing the jump height for backtracking."
#    else:
#        previous_out_of_reach_waypoint_label.text = ""
#
#    # Draw some text describing the current step.
#    step_label.rect_position = step_attempt.start_waypoint.position + LABEL_OFFSET
#    step_label.add_color_override("font_color", step_color)
#    var line_1 := "Step %s/%s:" % [step_attempt.index + 1, edge_attempt.total_step_count]
#    var line_2 := "\n        [Backtracking]" if step_attempt.is_backtracking else ""
#    var line_3 := "\n        [Replaced fake waypoint]" if \
#            step_attempt.replaced_a_fake else ""
#    var line_4: String = "\n        %s" % step_attempt.description_list[0]
#    var line_5: String = ("\n        %s" % step_attempt.description_list[1]) if \
#            step_attempt.description_list.size() > 1 else ""
#    step_label.text = line_1 + line_2 + line_3 + line_4 + line_5
#
#func _draw_invalid_edge() -> void:
#    var edge_start: Vector2 = edge_attempt.origin_waypoint.position
#    var edge_end: Vector2 = edge_attempt.destination_waypoint.position
#
#    _draw_invalid_trajectory(edge_start, edge_end)
#
#    # Draw some text describing the invalid edge.
#    step_label.rect_position = edge_start + LABEL_OFFSET
#    step_label.add_color_override("font_color", INVALID_EDGE_COLOR)
#    step_label.text = INVALID_EDGE_TEXT
#
#func _draw_invalid_trajectory( \
#        start: Vector2, \
#        end: Vector2) -> void:
#    var middle: Vector2 = start.linear_interpolate(end, 0.5)
#
#    # Render a dotted straight line with a bigger x in the middle for edge_attempts that have no
#    # step children.
#    DrawUtils.draw_dashed_line(self, start, end, INVALID_EDGE_COLOR, \
#            INVALID_EDGE_DASH_LENGTH, INVALID_EDGE_DASH_GAP, 0.0, \
#            INVALID_EDGE_DASH_STROKE_WIDTH)
#    DrawUtils.draw_x(self, middle, INVALID_EDGE_X_WIDTH, INVALID_EDGE_X_HEIGHT, \
#            INVALID_EDGE_COLOR, INVALID_EDGE_DASH_STROKE_WIDTH)
