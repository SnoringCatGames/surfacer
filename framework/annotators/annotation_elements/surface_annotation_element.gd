extends AnnotationElement
class_name SurfaceAnnotationElement

const TYPE := AnnotationElementType.SURFACE

var surface: Surface
var color_params: ColorParams
var depth: float

func _init( \
        surface: Surface, \
        color_params := AnnotationElementDefaults.SURFACE_COLOR_PARAMS, \
        depth := AnnotationElementDefaults.SURFACE_DEPTH) \
        .(TYPE) -> void:
    self.surface = surface
    self.color_params = color_params
    self.depth = depth

func draw(canvas: CanvasItem) -> void:
    draw_from_surface( \
            canvas, \
            surface, \
            color_params, \
            depth)

static func draw_from_surface( \
        canvas: CanvasItem, \
        surface: Surface, \
        color_params: ColorParams, \
        depth := AnnotationElementDefaults.SURFACE_DEPTH) -> void:
    var color := color_params.get_color()
    DrawUtils.draw_surface( \
            canvas, \
            surface, \
            color, \
            depth)

func _create_legend_items() -> Array:
    var surface_item := SurfaceLegendItem.new()
    return [surface_item]
