class_name SurfaceAnnotationElement
extends AnnotationElement

const DEFAULT_TYPE := AnnotationElementType.SURFACE

var surface: Surface
var depth: float
var color_params: ColorParams
var is_origin: bool
var is_destination: bool

func _init(
        surface: Surface,
        depth := AnnotationElementDefaults.SURFACE_DEPTH,
        color_params: ColorParams = \
                Surfacer.ann_defaults.SURFACE_COLOR_PARAMS,
        is_origin := false,
        is_destination := false,
        type := DEFAULT_TYPE) \
        .(type) -> void:
    self.surface = surface
    self.depth = depth
    self.color_params = color_params
    self.is_origin = is_origin
    self.is_destination = is_destination

func draw(canvas: CanvasItem) -> void:
    draw_from_surface(
            canvas,
            surface,
            color_params,
            depth)

static func draw_from_surface(
        canvas: CanvasItem,
        surface: Surface,
        color_params: ColorParams,
        depth := AnnotationElementDefaults.SURFACE_DEPTH) -> void:
    var color := color_params.get_color()
    Gs.draw_utils.draw_surface(
            canvas,
            surface,
            color,
            depth)

func _create_legend_items() -> Array:
    var surface_item := SurfaceLegendItem.new()
    return [surface_item]
