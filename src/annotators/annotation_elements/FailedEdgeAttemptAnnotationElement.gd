class_name FailedEdgeAttemptAnnotationElement
extends AnnotationElement

const TYPE := AnnotationElementType.FAILED_EDGE_ATTEMPT

var failed_edge_attempt: FailedEdgeAttempt
var end_color_params: ColorParams
var line_color_params: ColorParams
var end_radius: float
var dash_length: float
var dash_gap: float
var dash_stroke_width: float
var includes_surfaces: bool

func _init( \
        failed_edge_attempt: FailedEdgeAttempt,
        end_color_params := Surfacer.ann_defaults \
                .EDGE_DISCRETE_TRAJECTORY_COLOR_PARAMS,
        line_color_params := \
                Surfacer.ann_defaults.FAILED_EDGE_ATTEMPT_COLOR_PARAMS,
        dash_length := \
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_LENGTH,
        dash_gap := \
                AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_GAP,
        dash_stroke_width := AnnotationElementDefaults \
                .FAILED_EDGE_ATTEMPT_DASH_STROKE_WIDTH,
        includes_surfaces := AnnotationElementDefaults \
                .FAILED_EDGE_ATTEMPT_INCLUDES_SURFACES) \
        .(TYPE) -> void:
    assert(failed_edge_attempt != null)
    self.failed_edge_attempt = failed_edge_attempt
    self.end_color_params = end_color_params
    self.line_color_params = line_color_params
    self.end_radius = end_radius
    self.dash_length = dash_length
    self.dash_gap = dash_gap
    self.dash_stroke_width = dash_stroke_width
    self.includes_surfaces = includes_surfaces

func draw(canvas: CanvasItem) -> void:
    var end_color := end_color_params.get_color()
    var line_color := line_color_params.get_color()
    var start := failed_edge_attempt.get_start()
    var end := failed_edge_attempt.get_end()
    var middle: Vector2 = start.linear_interpolate(end, 0.5)
    Gs.draw_utils.draw_dashed_line( \
            canvas,
            start,
            end,
            line_color,
            dash_length,
            dash_gap,
            0.0,
            dash_stroke_width)
    Gs.draw_utils.draw_x( \
            canvas,
            middle,
            AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_X_WIDTH,
            AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_X_HEIGHT,
            line_color,
            dash_stroke_width)
    Gs.draw_utils.draw_origin_marker( \
            canvas,
            start,
            end_color)
    Gs.draw_utils.draw_destination_marker( \
            canvas,
            end,
            true,
            failed_edge_attempt.get_end_surface().side,
            end_color)
    if includes_surfaces:
        SurfaceAnnotationElement.draw_from_surface( \
                canvas,
                failed_edge_attempt.get_start_surface(),
                end_color_params)
        SurfaceAnnotationElement.draw_from_surface( \
                canvas,
                failed_edge_attempt.get_end_surface(),
                end_color_params)

func _create_legend_items() -> Array:
    var failed_edge_item := FailedEdgeTrajectoryLegendItem.new()
    var origin_item := OriginLegendItem.new()
    var destination_item := DestinationLegendItem.new()
    return [
        failed_edge_item,
        origin_item,
        destination_item,
    ]
