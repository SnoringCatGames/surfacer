class_name EdgeStepAnnotationElement
extends AnnotationElement


const TYPE := AnnotationElementType.EDGE_STEP

const LABEL_SCALE := 0.5

var step_result_metadata: EdgeStepCalcResultMetadata
var renders_faintly: bool
var opacity: float
var trajectory_stroke_width: float
var waypoint_stroke_width: float
var collision_color: Color
var collision_x_stroke_width: float
var collision_character_boundary_stroke_width: float
var color: Color

var step_label: ScaffolderLabel
var previous_out_of_reach_waypoint_label: ScaffolderLabel


func _init(
        step_result_metadata: EdgeStepCalcResultMetadata,
        renders_faintly: bool) \
        .(TYPE) -> void:
    self.step_result_metadata = step_result_metadata
    self.renders_faintly = renders_faintly
    
    if renders_faintly:
        self.opacity = \
                AnnotationElementDefaults.STEP_OPACITY_FAINT
        self.trajectory_stroke_width = \
                AnnotationElementDefaults.STEP_TRAJECTORY_STROKE_WIDTH_FAINT
        self.waypoint_stroke_width = \
                AnnotationElementDefaults.WAYPOINT_STROKE_WIDTH_FAINT
        self.collision_color = \
                Su.ann_defaults.COLLISION_COLOR_FAINT
        self.collision_x_stroke_width = \
                AnnotationElementDefaults.COLLISION_X_STROKE_WIDTH_FAINT
        self.collision_character_boundary_stroke_width = \
                AnnotationElementDefaults \
                        .COLLISION_CHARACTER_BOUNDARY_STROKE_WIDTH_FAINT
    else:
        self.opacity = \
                AnnotationElementDefaults.STEP_OPACITY_STRONG
        self.trajectory_stroke_width = \
                AnnotationElementDefaults.STEP_TRAJECTORY_STROKE_WIDTH_STRONG
        self.waypoint_stroke_width = \
                AnnotationElementDefaults.WAYPOINT_STROKE_WIDTH_STRONG
        self.collision_color = \
                Su.ann_defaults.COLLISION_COLOR_STRONG
        self.collision_x_stroke_width = \
                AnnotationElementDefaults.COLLISION_X_STROKE_WIDTH_STRONG
        self.collision_character_boundary_stroke_width = \
                AnnotationElementDefaults \
                        .COLLISION_CHARACTER_BOUNDARY_STROKE_WIDTH_STRONG
    
    self.color = _calculate_color(renders_faintly)
    
    _create_labels()


func _calculate_color(renders_faintly: bool) -> Color:
    # Hue transitions evenly from start to end.
    var total_step_count := \
            step_result_metadata.edge_result_metadata.total_step_count
    var step_ratio := \
            (step_result_metadata.index / (total_step_count - 1.0)) if \
            total_step_count > 1 else \
            1.0
    var step_hue: float = \
            AnnotationElementDefaults.STEP_HUE_START + \
            (AnnotationElementDefaults.STEP_HUE_END - \
                    AnnotationElementDefaults.STEP_HUE_START) * \
            step_ratio
    return Color.from_hsv(
            step_hue,
            AnnotationElementDefaults.STEP_SATURATION,
            AnnotationElementDefaults.STEP_VALUE,
            opacity)


func _create_labels() -> void:
    step_label = Sc.utils.add_scene(
            null, Sc.gui.SCAFFOLDER_LABEL_SCENE, false, true)
    step_label.font_size = "Xs"
    step_label.rect_scale = Vector2(LABEL_SCALE, LABEL_SCALE)
    step_label.align = Label.ALIGN_LEFT
    
    previous_out_of_reach_waypoint_label = Sc.utils.add_scene(
            null, Sc.gui.SCAFFOLDER_LABEL_SCENE, false, true)
    previous_out_of_reach_waypoint_label.font_size = "Xs"
    previous_out_of_reach_waypoint_label.rect_scale = \
            Vector2(LABEL_SCALE, LABEL_SCALE)
    previous_out_of_reach_waypoint_label.align = Label.ALIGN_LEFT


func draw(canvas: CanvasItem) -> void:
    _attach_labels(canvas)
    _draw_trajectory(canvas)
    _draw_step_end_points(canvas)
    _draw_collision(canvas)
    _draw_backtracking_waypoint(canvas)
    _draw_description(canvas)


func _destroy() -> void:
    step_label.queue_free()
    previous_out_of_reach_waypoint_label.queue_free()


func _draw_trajectory(canvas: CanvasItem) -> void:
    var step := step_result_metadata.step
    if step != null and step.frame_positions.size() > 1:
        # Draw the valid step trajectory.
        Sc.draw.draw_dashed_polyline(
                canvas,
                PoolVector2Array(step.frame_positions),
                color,
                AnnotationElementDefaults.STEP_TRAJECTORY_DASH_LENGTH,
                AnnotationElementDefaults.STEP_TRAJECTORY_DASH_GAP,
                0.0,
                trajectory_stroke_width)
    else:
        # The calculation failed before a step object could be created.
        _draw_invalid_trajectory(canvas)


func _draw_step_end_points(canvas: CanvasItem) -> void:
    # Draw the step end points.
    Sc.draw.draw_circle_outline(
            canvas,
            step_result_metadata.get_start().position,
            AnnotationElementDefaults.WAYPOINT_RADIUS,
            color,
            waypoint_stroke_width,
            4.0)
    Sc.draw.draw_circle_outline(
            canvas,
            step_result_metadata.get_end().position,
            AnnotationElementDefaults.WAYPOINT_RADIUS,
            color,
            waypoint_stroke_width,
            4.0)


func _draw_collision(canvas: CanvasItem) -> void:
    var collision_result_metadata := \
            step_result_metadata.collision_result_metadata
    
    # Draw any collision.
    if collision_result_metadata != null and \
            collision_result_metadata.collision != null:
        var collision := collision_result_metadata.collision
        if collision.position != Vector2.INF:
            # Draw an X at the actual point of collision.
            Sc.draw.draw_x(
                    canvas,
                    collision.position,
                    AnnotationElementDefaults.COLLISION_X_WIDTH_HEIGHT.x,
                    AnnotationElementDefaults.COLLISION_X_WIDTH_HEIGHT.y,
                    collision_color,
                    collision_x_stroke_width)
        
        if !renders_faintly and collision.surface != null:
            # Draw the surface that was collided with.
            Sc.draw.draw_surface(
                    canvas,
                    collision.surface,
                    collision_color)
        
        # Draw an outline of the character's collision boundary at the point of
        # collision.
        Sc.draw.draw_shape_outline(
                canvas,
                collision.character_position,
                collision_result_metadata.collider_shape,
                collision_result_metadata.collider_rotation,
                collision_color,
                collision_character_boundary_stroke_width)
        # Draw a dot at the center of the character's collision boundary.
        canvas.draw_circle(
                collision.character_position,
                AnnotationElementDefaults \
                        .COLLISION_CHARACTER_BOUNDARY_CENTER_RADIUS,
                collision_color)
        
        if !renders_faintly:
            # Draw the upcoming waypoints, around the collision.
            for upcoming_waypoint in step_result_metadata.upcoming_waypoints:
                if upcoming_waypoint.is_valid:
                    Sc.draw.draw_checkmark(
                            canvas,
                            upcoming_waypoint.position,
                            AnnotationElementDefaults.VALID_WAYPOINT_WIDTH,
                            color,
                            AnnotationElementDefaults \
                                    .VALID_WAYPOINT_STROKE_WIDTH)
                else:
                    Sc.draw.draw_x(
                            canvas,
                            upcoming_waypoint.position,
                            AnnotationElementDefaults.INVALID_WAYPOINT_WIDTH,
                            AnnotationElementDefaults \
                                    .INVALID_WAYPOINT_HEIGHT,
                            color,
                            AnnotationElementDefaults \
                                    .INVALID_WAYPOINT_STROKE_WIDTH)
            
            # Draw the bounding boxes at frame start, end, and previous.
            _draw_bounding_box_and_margin(
                    canvas,
                    collision_result_metadata.frame_start_position,
                    Su.ann_defaults.COLLISION_FRAME_START_COLOR)
            _draw_bounding_box_and_margin(
                    canvas,
                    collision_result_metadata.frame_end_position,
                    Su.ann_defaults.COLLISION_FRAME_END_COLOR)
            _draw_bounding_box_and_margin(
                    canvas,
                    collision_result_metadata.frame_previous_position,
                    Su.ann_defaults.COLLISION_FRAME_PREVIOUS_COLOR)


func _draw_bounding_box_and_margin(
        canvas: CanvasItem,
        center: Vector2,
        color: Color) -> void:
    var collision_result_metadata := \
            step_result_metadata.collision_result_metadata
    Sc.draw.draw_rectangle_outline(
            canvas,
            center,
            collision_result_metadata.collider_half_width_height,
            false,
            color,
            AnnotationElementDefaults.COLLISION_BOUNDING_BOX_STROKE_WIDTH)
    Sc.draw.draw_dashed_rectangle(
            canvas,
            center,
            collision_result_metadata.collider_half_width_height + \
                    Vector2(collision_result_metadata.margin,
                            collision_result_metadata.margin),
            false,
            color,
            AnnotationElementDefaults.COLLISION_MARGIN_DASH_LENGTH,
            AnnotationElementDefaults.COLLISION_MARGIN_DASH_GAP,
            0.0,
            AnnotationElementDefaults.COLLISION_MARGIN_STROKE_WIDTH,
            false)


func _draw_backtracking_waypoint(canvas: CanvasItem) -> void:
    # For new backtracking steps, draw and label the waypoint that was used as
    # the basis for a
    # higher jump.
    if step_result_metadata.get_is_backtracking() and \
            !renders_faintly:
        # Draw the waypoint position.
        Sc.draw.draw_diamond_outline(
                canvas,
                step_result_metadata.previous_out_of_reach_waypoint.position,
                AnnotationElementDefaults \
                        .PREVIOUS_OUT_OF_REACH_WAYPOINT_WIDTH_HEIGHT,
                AnnotationElementDefaults \
                        .PREVIOUS_OUT_OF_REACH_WAYPOINT_WIDTH_HEIGHT,
                color,
                1.0)
        
        # Label the waypoint.
        previous_out_of_reach_waypoint_label.rect_position = \
                step_result_metadata.previous_out_of_reach_waypoint \
                        .position + \
                AnnotationElementDefaults.LABEL_OFFSET
        previous_out_of_reach_waypoint_label.add_color_override(
                "font_color",
                color)
        previous_out_of_reach_waypoint_label.text = (
                "The previously out-of-reach waypoint that was the basis\n" +
                "for increasing the jump height for backtracking.")
    else:
        previous_out_of_reach_waypoint_label.text = ""


func _draw_description(canvas: CanvasItem) -> void:
    if !renders_faintly:
        # Draw some text describing the current step.
        step_label.rect_position = \
                step_result_metadata.get_start().position + \
                AnnotationElementDefaults.LABEL_OFFSET
        step_label.add_color_override("font_color", color)
        var description_list := step_result_metadata.get_description_list()
        var line_1 := "Step %s/%s:" % [
            step_result_metadata.index + 1,
            step_result_metadata.edge_result_metadata.total_step_count,
        ]
        var line_2 := \
                "\n        [Backtracking]" if \
                step_result_metadata.get_is_backtracking() else \
                ""
        var line_3 := \
                "\n        [Replaced fake waypoint]" if \
                step_result_metadata.get_replaced_a_fake() else \
                ""
        var line_4: String = \
                "\n        %s" % description_list[0]
        var line_5: String = \
                ("\n        %s" % description_list[1]) if \
                description_list.size() > 1 else \
                ""
        step_label.text = line_1 + line_2 + line_3 + line_4 + line_5
    else:
        step_label.text = ""


func _draw_invalid_trajectory(canvas: CanvasItem) -> void:
    var start := step_result_metadata.get_start().position
    var end := step_result_metadata.get_end().position
    var middle: Vector2 = start.linear_interpolate(end, 0.5)
    
    # Render a dotted straight line with a bigger x in the middle for invalid
    # steps.
    Sc.draw.draw_dashed_line(
            canvas,
            start,
            end,
            Su.ann_defaults.INVALID_EDGE_COLOR_PARAMS.get_color(),
            AnnotationElementDefaults.INVALID_EDGE_DASH_LENGTH,
            AnnotationElementDefaults.INVALID_EDGE_DASH_GAP,
            0.0,
            AnnotationElementDefaults.INVALID_EDGE_DASH_STROKE_WIDTH)
    Sc.draw.draw_x(
            canvas,
            middle,
            AnnotationElementDefaults.INVALID_EDGE_X_WIDTH,
            AnnotationElementDefaults.INVALID_EDGE_X_HEIGHT,
            Su.ann_defaults.INVALID_EDGE_COLOR_PARAMS.get_color(),
            AnnotationElementDefaults.INVALID_EDGE_DASH_STROKE_WIDTH)


func _attach_labels(canvas: CanvasItem) -> void:
    var old_parent := step_label.get_parent()
    if old_parent != canvas:
        if old_parent != null:
            old_parent.remove_child(step_label)
            old_parent.remove_child(previous_out_of_reach_waypoint_label)
        canvas.add_child(step_label)
        canvas.add_child(previous_out_of_reach_waypoint_label)


func _create_legend_items() -> Array:
    # TODO
    return []
