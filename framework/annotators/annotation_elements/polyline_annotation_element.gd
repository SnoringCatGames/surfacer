extends AnnotationElement
class_name PolylineAnnotationElement

const TYPE := AnnotationElementType.POLYLINE

var vertices: Array
var legend_item_text: String
var color_params: ColorParams
var is_filled: bool
var is_dashed: bool
var dash_length: float
var dash_gap: float
var stroke_width: float

func _init( \
        vertices: Array, \
        legend_item_text: String, \
        color_params := AnnotationElementDefaults \
                .DEFAULT_POLYLINE_COLOR_PARAMS, \
        is_filled := false, \
        is_dashed := false, \
        dash_length := \
                AnnotationElementDefaults.DEFAULT_POLYLINE_DASH_LENGTH, \
        dash_gap := \
                AnnotationElementDefaults.DEFAULT_POLYLINE_DASH_GAP, \
        stroke_width := AnnotationElementDefaults \
                .DEFAULT_POLYLINE_STROKE_WIDTH) \
        .(TYPE) -> void:
    assert(!is_filled or !is_dashed)
    self.vertices = vertices
    self.legend_item_text = legend_item_text
    self.color_params = color_params
    self.is_filled = is_filled
    self.is_dashed = is_dashed
    self.dash_length = dash_length
    self.dash_gap = dash_gap
    self.stroke_width = stroke_width

func draw(canvas: CanvasItem) -> void:
    var color := color_params.get_color()
    if is_filled:
        canvas.draw_colored_polygon( \
                PoolVector2Array(vertices), \
                color)
    elif is_dashed:
        DrawUtils.draw_dashed_polyline( \
                canvas, \
                vertices, \
                color, \
                dash_length, \
                dash_gap, \
                0.0, \
                stroke_width)
    else:
        canvas.draw_polyline( \
                PoolVector2Array(vertices), \
                color, \
                stroke_width)

func _create_legend_items() -> Array:
    return [PolylineLegendItem.new(legend_item_text)]
