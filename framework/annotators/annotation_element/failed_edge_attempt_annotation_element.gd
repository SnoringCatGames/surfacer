extends AnnotationElement
class_name FailedEdgeAttemptAnnotationElement

const TYPE := AnnotationElementType.FAILED_EDGE_ATTEMPT

var failed_edge_attempt: FailedEdgeAttempt
var color_params: ColorParams
var radius: float
var dash_length: float
var dash_gap: float
var dash_stroke_width: float
var includes_surfaces: bool

func _init( \
        failed_edge_attempt: FailedEdgeAttempt, \
        color_params := \
                AnnotationElementDefaults_.FAILED_EDGE_ATTEMPT_COLOR_PARAMS, \
        radius := \
                AnnotationElementDefaults_.FAILED_EDGE_ATTEMPT_RADIUS, \
        dash_length := \
                AnnotationElementDefaults_.FAILED_EDGE_ATTEMPT_DASH_LENGTH, \
        dash_gap := \
                AnnotationElementDefaults_.FAILED_EDGE_ATTEMPT_DASH_GAP, \
        dash_stroke_width := \
                AnnotationElementDefaults_.FAILED_EDGE_ATTEMPT_DASH_STROKE_WIDTH, \
        includes_surfaces := \
                AnnotationElementDefaults_.FAILED_EDGE_ATTEMPT_INCLUDES_SURFACES) \
        .(TYPE) -> void:
    self.failed_edge_attempt = failed_edge_attempt
    self.color_params = color_params
    self.radius = radius
    self.dash_length = dash_length
    self.dash_gap = dash_gap
    self.dash_stroke_width = dash_stroke_width
    self.includes_surfaces = includes_surfaces

func draw(canvas: CanvasItem) -> void:
    var color := color_params.get_color()
    var start := failed_edge_attempt.start
    var end := failed_edge_attempt.end
    DrawUtils.draw_dashed_line( \
            canvas, \
            start, \
            end, \
            color, \
            dash_length, \
            dash_gap, \
            0.0, \
            dash_stroke_width)
    canvas.draw_circle( \
            start, \
            radius, \
            color)
    canvas.draw_circle( \
            end, \
            radius, \
            color)
    if includes_surfaces:
        SurfaceAnnotationElement.draw_from_surface( \
                canvas, \
                failed_edge_attempt.start_surface, \
                color_params)
        SurfaceAnnotationElement.draw_from_surface( \
                canvas, \
                failed_edge_attempt.end_surface, \
                color_params)
