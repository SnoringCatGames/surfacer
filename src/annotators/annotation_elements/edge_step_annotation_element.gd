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
                Sc.ann_params.step_opacity_faint
        self.trajectory_stroke_width = \
                Sc.ann_params.step_trajectory_stroke_width_faint
        self.waypoint_stroke_width = \
                Sc.ann_params.waypoint_stroke_width_faint
        self.collision_color = \
                Sc.ann_params.collision_color_faint
        self.collision_x_stroke_width = \
                Sc.ann_params.collision_x_stroke_width_faint
        self.collision_character_boundary_stroke_width = \
                Sc.ann_params.collision_character_boundary_stroke_width_faint
    else:
        self.opacity = \
                Sc.ann_params.step_opacity_strong
        self.trajectory_stroke_width = \
                Sc.ann_params.step_trajectory_stroke_width_strong
        self.waypoint_stroke_width = \
                Sc.ann_params.waypoint_stroke_width_strong
        self.collision_color = \
                Sc.ann_params.collision_color_strong
        self.collision_x_stroke_width = \
                Sc.ann_params.collision_x_stroke_width_strong
        self.collision_character_boundary_stroke_width = \
                Sc.ann_params.collision_character_boundary_stroke_width_strong
    
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
            Sc.ann_params.step_hue_start + \
            (Sc.ann_params.step_hue_end - \
                    Sc.ann_params.step_hue_start) * \
            step_ratio
    return Color.from_hsv(
            step_hue,
            Sc.ann_params.step_saturation,
            Sc.ann_params.step_value,
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
                Sc.ann_params.step_trajectory_dash_length,
                Sc.ann_params.step_trajectory_dash_gap,
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
            Sc.ann_params.waypoint_radius,
            color,
            waypoint_stroke_width,
            4.0)
    Sc.draw.draw_circle_outline(
            canvas,
            step_result_metadata.get_end().position,
            Sc.ann_params.waypoint_radius,
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
                    Sc.ann_params.collision_x_width_height.x,
                    Sc.ann_params.collision_x_width_height.y,
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
                collision_result_metadata.collider,
                collision_color,
                collision_character_boundary_stroke_width)
        # Draw a dot at the center of the character's collision boundary.
        canvas.draw_circle(
                collision.character_position,
                Sc.ann_params.collision_character_boundary_center_radius,
                collision_color)
        
        if !renders_faintly:
            # Draw the upcoming waypoints, around the collision.
            for upcoming_waypoint in step_result_metadata.upcoming_waypoints:
                if upcoming_waypoint.is_valid:
                    Sc.draw.draw_checkmark(
                            canvas,
                            upcoming_waypoint.position,
                            Sc.ann_params.valid_waypoint_width,
                            color,
                            Sc.ann_params.valid_waypoint_stroke_width)
                else:
                    Sc.draw.draw_x(
                            canvas,
                            upcoming_waypoint.position,
                            Sc.ann_params.invalid_waypoint_width,
                            Sc.ann_params.invalid_waypoint_height,
                            color,
                            Sc.ann_params.invalid_waypoint_stroke_width)
            
            # Draw the bounding boxes at frame start, end, and previous.
            _draw_bounding_box_and_margin(
                    canvas,
                    collision_result_metadata.frame_start_position,
                    Sc.ann_params.collision_frame_start_color)
            _draw_bounding_box_and_margin(
                    canvas,
                    collision_result_metadata.frame_end_position,
                    Sc.ann_params.collision_frame_end_color)
            _draw_bounding_box_and_margin(
                    canvas,
                    collision_result_metadata.frame_previous_position,
                    Sc.ann_params.collision_frame_previous_color)


func _draw_bounding_box_and_margin(
        canvas: CanvasItem,
        center: Vector2,
        color: Color) -> void:
    var collision_result_metadata := \
            step_result_metadata.collision_result_metadata
    Sc.draw.draw_rectangle_outline(
            canvas,
            center,
            collision_result_metadata.collider.half_width_height,
            false,
            color,
            Sc.ann_params.collision_bounding_box_stroke_width)
    Sc.draw.draw_dashed_rectangle(
            canvas,
            center,
            collision_result_metadata.collider.half_width_height + \
                    Vector2(collision_result_metadata.margin,
                            collision_result_metadata.margin),
            false,
            color,
            Sc.ann_params.collision_margin_dash_length,
            Sc.ann_params.collision_margin_dash_gap,
            0.0,
            Sc.ann_params.collision_margin_stroke_width,
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
                Sc.ann_params.previous_out_of_reach_waypoint_width_height,
                Sc.ann_params.previous_out_of_reach_waypoint_width_height,
                color,
                1.0)
        
        # Label the waypoint.
        previous_out_of_reach_waypoint_label.rect_position = \
                step_result_metadata.previous_out_of_reach_waypoint \
                        .position + \
                Sc.ann_params.label_offset
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
                Sc.ann_params.label_offset
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
            Sc.ann_params.invalid_edge_color_params.get_color(),
            Sc.ann_params.invalid_edge_dash_length,
            Sc.ann_params.invalid_edge_dash_gap,
            0.0,
            Sc.ann_params.invalid_edge_dash_stroke_width)
    Sc.draw.draw_x(
            canvas,
            middle,
            Sc.ann_params.invalid_edge_x_width,
            Sc.ann_params.invalid_edge_x_height,
            Sc.ann_params.invalid_edge_color_params.get_color(),
            Sc.ann_params.invalid_edge_dash_stroke_width)


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
