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
        depth := Sc.ann_params.surface_depth,
        color_params: ColorParams = \
                Sc.ann_params.surface_color_params,
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
    _draw_from_surface(
            canvas,
            surface,
            color_params,
            depth)


func _create_legend_items() -> Array:
    var surface_item := SurfaceLegendItem.new()
    return [surface_item]
