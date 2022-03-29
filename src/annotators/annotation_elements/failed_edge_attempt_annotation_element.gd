class_name FailedEdgeAttemptAnnotationElement
extends SurfacerAnnotationElement


const TYPE := AnnotationElementType.FAILED_EDGE_ATTEMPT

var failed_edge_attempt: FailedEdgeAttempt
var end_color: Color
var line_color: Color
var end_radius: float
var dash_length: float
var dash_gap: float
var dash_stroke_width: float
var includes_surfaces: bool


func _init(
        failed_edge_attempt: FailedEdgeAttempt,
        end_color := Sc.annotators.params.edge_discrete_trajectory_color,
        line_color := Sc.palette.get_color("failed_edge_attempt_color"),
        dash_length := Sc.annotators.params.failed_edge_attempt_dash_length,
        dash_gap := Sc.annotators.params.failed_edge_attempt_dash_gap,
        dash_stroke_width := Sc.annotators.params \
                .failed_edge_attempt_dash_stroke_width,
        includes_surfaces := Sc.annotators.params \
                .failed_edge_attempt_includes_surfaces) \
        .(TYPE) -> void:
    assert(failed_edge_attempt != null)
    self.failed_edge_attempt = failed_edge_attempt
    self.end_color = end_color
    self.line_color = line_color
    self.end_radius = end_radius
    self.dash_length = dash_length
    self.dash_gap = dash_gap
    self.dash_stroke_width = dash_stroke_width
    self.includes_surfaces = includes_surfaces


func draw(canvas: CanvasItem) -> void:
    var start := failed_edge_attempt.get_start()
    var end := failed_edge_attempt.get_end()
    var middle: Vector2 = start.linear_interpolate(end, 0.5)
    Sc.draw.draw_dashed_line(
            canvas,
            start,
            end,
            line_color,
            dash_length,
            dash_gap,
            0.0,
            dash_stroke_width)
    Sc.draw.draw_x(
            canvas,
            middle,
            Sc.annotators.params.failed_edge_attempt_x_width,
            Sc.annotators.params.failed_edge_attempt_x_height,
            line_color,
            dash_stroke_width)
    Sc.draw.draw_origin_marker(
            canvas,
            start,
            end_color)
    Sc.draw.draw_destination_marker(
            canvas,
            failed_edge_attempt.end_position_along_surface,
            true,
            end_color)
    if includes_surfaces:
        _draw_from_surface(
                canvas,
                failed_edge_attempt.get_start_surface(),
                end_color)
        _draw_from_surface(
                canvas,
                failed_edge_attempt.get_end_surface(),
                end_color)


func _create_legend_items() -> Array:
    var failed_edge_item := FailedEdgeTrajectoryLegendItem.new()
    var origin_item := OriginLegendItem.new()
    var destination_item := DestinationLegendItem.new()
    return [
        failed_edge_item,
        origin_item,
        destination_item,
    ]
