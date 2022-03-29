class_name PolylineLegendItem
extends LegendItem


const NORMALIZED_FAKE_POSITIONS := [
    Vector2(0.15, 0.0),
    Vector2(0.85, 0.0),
    Vector2(1.0, 1.0),
    Vector2(0.0, 1.0),
    Vector2(0.15, 0.0),
]
const SCALE := 0.8

var color: Color
var is_filled: bool
var is_dashed: bool
var dash_length: float
var dash_gap: float
var stroke_width: float


func _init(
        type: String,
        text: String,
        color: Color,
        is_filled: bool,
        is_dashed: bool,
        dash_length: float,
        dash_gap: float,
        stroke_width: float) \
        .(
        type,
        text) -> void:
    assert(!is_filled or !is_dashed)
    self.color = color
    self.is_filled = is_filled
    self.is_dashed = is_dashed
    self.dash_length = dash_length
    self.dash_gap = dash_gap
    self.stroke_width = stroke_width


func _draw_shape(
        center: Vector2,
        size: Vector2) -> void:
    var offset := center - 0.5 * size * SCALE
    var vertices := []
    vertices.resize(NORMALIZED_FAKE_POSITIONS.size())
    for i in NORMALIZED_FAKE_POSITIONS.size():
        vertices[i] = NORMALIZED_FAKE_POSITIONS[i] * size * SCALE + offset
    
    if is_filled:
        draw_colored_polygon(
                PoolVector2Array(vertices),
                color)
    elif is_dashed:
        Sc.draw.draw_dashed_polyline(
                self,
                vertices,
                color,
                dash_length,
                dash_gap,
                0.0,
                stroke_width)
    else:
        draw_polyline(
                PoolVector2Array(vertices),
                color,
                stroke_width)
