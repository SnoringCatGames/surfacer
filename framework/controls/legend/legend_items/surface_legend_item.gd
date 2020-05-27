extends LegendItem
class_name SurfaceLegendItem

const DEFAULT_TYPE := LegendItemType.SURFACE
const DEFAULT_TEXT := "Surface"
var DEFAULT_COLOR := Colors.opacify(Colors.YELLOW, Colors.ALPHA_FAINT)
const SURFACE_DEPTH := 8.1

var color: Color

func _init( \
        type := DEFAULT_TYPE, \
        text := DEFAULT_TEXT, \
        color := DEFAULT_COLOR).( \
        type, \
        text) -> void:
    self.color = color

func _draw_shape( \
        center: Vector2, \
        size: Vector2) -> void:
    var vertices := [ \
            Vector2(center.x - size.x / 2.0, center.y), \
            Vector2(center.x + size.x / 2.0, center.y), \
            ]
    var surface := Surface.new( \
            vertices, \
            SurfaceSide.FLOOR, \
            null, \
            [])
    DrawUtils.draw_surface( \
            self, \
            surface, \
            color, \
            SURFACE_DEPTH)
