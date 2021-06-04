class_name PolylineAnnotationElement
extends AnnotationElement

var legend_item_class_reference
var vertices: Array
var color_params: ColorParams
var is_filled: bool
var is_dashed: bool
var dash_length: float
var dash_gap: float
var stroke_width: float


func _init(
        type: int,
        legend_item_class_reference,
        vertices: Array,
        color_params: ColorParams,
        is_filled: bool,
        is_dashed: bool,
        dash_length: float,
        dash_gap: float,
        stroke_width: float) \
        .(type) -> void:
    assert(!is_filled or !is_dashed)
    self.legend_item_class_reference = legend_item_class_reference
    self.vertices = vertices
    self.color_params = color_params
    self.is_filled = is_filled
    self.is_dashed = is_dashed
    self.dash_length = dash_length
    self.dash_gap = dash_gap
    self.stroke_width = stroke_width


func draw(canvas: CanvasItem) -> void:
    var color := color_params.get_color()
    if is_filled:
        canvas.draw_colored_polygon(
                PoolVector2Array(vertices),
                color)
    elif is_dashed:
        Gs.draw_utils.draw_dashed_polyline(
                canvas,
                vertices,
                color,
                dash_length,
                dash_gap,
                0.0,
                stroke_width)
    else:
        canvas.draw_polyline(
                PoolVector2Array(vertices),
                color,
                stroke_width)


func _create_legend_items() -> Array:
    var legend_item: PolylineLegendItem = legend_item_class_reference.new(
            color_params,
            is_filled,
            is_dashed,
            dash_length,
            dash_gap,
            stroke_width)
    return [legend_item]
