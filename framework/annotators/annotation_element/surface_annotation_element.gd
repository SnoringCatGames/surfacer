extends AnnotationElement
class_name SurfaceAnnotationElement

const SURFACE_DEPTH := DrawUtils.SURFACE_DEPTH

const TYPE := AnnotationElementType.SURFACE

var surface: Surface
var color: Color
var depth: float

func _init( \
        surface: Surface, \
        color: Color, \
        depth := SURFACE_DEPTH) \
        .(TYPE) -> void:
    self.surface = surface
    self.color = color
    self.depth = depth

func draw(canvas: CanvasItem) -> void:
    DrawUtils.draw_surface( \
            canvas, \
            surface, \
            color, \
            depth)
