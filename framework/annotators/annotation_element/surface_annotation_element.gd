extends AnnotationElement
class_name SurfaceAnnotationElement

const SURFACE_DEPTH := DrawUtils.SURFACE_DEPTH

const TYPE := AnnotationElementType.SURFACE

var surface: Surface
var color_params: ColorParams
var depth: float

func _init( \
        surface: Surface, \
        color_params: ColorParams, \
        depth := SURFACE_DEPTH) \
        .(TYPE) -> void:
    self.surface = surface
    self.color_params = color_params
    self.depth = depth

func draw(canvas: CanvasItem) -> void:
    var color := color_params.get_color()
    DrawUtils.draw_surface( \
            canvas, \
            surface, \
            color, \
            depth)
