class_name SurfaceLegendItem
extends LegendItem


const DEFAULT_TYPE := LegendItemType.SURFACE
const DEFAULT_TEXT := "Surface"
var DEFAULT_COLOR_PARAMS: ColorParams = \
        Sc.ann_params.default_surface_color_params
const surface_depth := 8.1

var color_params: ColorParams


func _init(
        type := DEFAULT_TYPE,
        text := DEFAULT_TEXT,
        color_params := DEFAULT_COLOR_PARAMS) \
        .(
        type,
        text) -> void:
    self.color_params = color_params


func _draw_shape(
        center: Vector2,
        size: Vector2) -> void:
    var vertices := [
            Vector2(center.x - size.x / 2.0, center.y),
            Vector2(center.x + size.x / 2.0, center.y),
            ]
    var surface := Surface.new(
            vertices,
            SurfaceSide.FLOOR,
            null,
            [])
    Sc.draw.draw_surface(
            self,
            surface,
            color_params.get_color(),
            Sc.ann_params.surface_depth)
