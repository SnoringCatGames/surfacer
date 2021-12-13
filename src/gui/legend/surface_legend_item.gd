class_name SurfaceLegendItem
extends LegendItem


const DEFAULT_TYPE := "SURFACE"
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
    var top_left := Vector2(center.x - size.x / 2.0, center.y)
    var top_right := Vector2(center.x + size.x / 2.0, center.y)
    var bottom_right := Vector2(center.x + size.x / 2.0, center.y + 100.0)
    var bottom_left := Vector2(center.x - size.x / 2.0, center.y + 100.0)
    
    var surface := Surface.new(
            [top_left, top_right],
            SurfaceSide.FLOOR,
            null,
            [])
    var clockwise_neighbor := Surface.new(
            [top_right, bottom_right],
            SurfaceSide.LEFT_WALL,
            null,
            [])
    var counter_clockwise_neighbor := Surface.new(
            [bottom_left, top_left],
            SurfaceSide.RIGHT_WALL,
            null,
            [])
    surface.clockwise_convex_neighbor = clockwise_neighbor
    surface.counter_clockwise_convex_neighbor = counter_clockwise_neighbor
    
    Sc.draw.draw_surface(
            self,
            surface,
            color_params.get_color(),
            Sc.ann_params.surface_depth)
