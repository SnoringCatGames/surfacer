class_name SurfaceAnnotationElement
extends SurfacerAnnotationElement


const DEFAULT_TYPE := AnnotationElementType.SURFACE

var surface: Surface
var depth: float
var color_config: ColorConfig
var is_origin: bool
var is_destination: bool


func _init(
        surface: Surface,
        depth := Sc.annotators.params.surface_depth,
        color_config: ColorConfig = \
                Sc.annotators.params.surface_color_config,
        is_origin := false,
        is_destination := false,
        type := DEFAULT_TYPE) \
        .(type) -> void:
    self.surface = surface
    self.depth = depth
    self.color_config = color_config
    self.is_origin = is_origin
    self.is_destination = is_destination


func draw(canvas: CanvasItem) -> void:
    _draw_from_surface(
            canvas,
            surface,
            color_config,
            depth)


func _create_legend_items() -> Array:
    var surface_item := SurfaceLegendItem.new()
    return [surface_item]
