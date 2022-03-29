class_name PolylineAnnotationElement
extends SurfacerAnnotationElement


var legend_item_class_reference
var vertices: Array
var color: Color
var is_filled: bool
var is_dashed: bool
var dash_length: float
var dash_gap: float
var stroke_width: float


func _init(
        type: int,
        legend_item_class_reference,
        vertices: Array,
        color: Color,
        is_filled: bool,
        is_dashed: bool,
        dash_length: float,
        dash_gap: float,
        stroke_width: float) \
        .(type) -> void:
    assert(!is_filled or !is_dashed)
    self.legend_item_class_reference = legend_item_class_reference
    self.vertices = vertices
    self.color = color
    self.is_filled = is_filled
    self.is_dashed = is_dashed
    self.dash_length = dash_length
    self.dash_gap = dash_gap
    self.stroke_width = stroke_width


func draw(canvas: CanvasItem) -> void:
    if is_filled:
        canvas.draw_colored_polygon(
                PoolVector2Array(vertices),
                color)
    elif is_dashed:
        Sc.draw.draw_dashed_polyline(
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
            color,
            is_filled,
            is_dashed,
            dash_length,
            dash_gap,
            stroke_width)
    return [legend_item]
