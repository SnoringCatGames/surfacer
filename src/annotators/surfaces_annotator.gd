class_name SurfacesAnnotator
extends Node2D


var surface_parser: SurfaceParser
var color_params: ColorParams = Su.ann_defaults.SURFACE_COLOR_PARAMS
var alpha_with_inspector_closed := 0.9
var alpha_with_inspector_open := alpha_with_inspector_closed * 0.2

var was_inspector_open := false


func _init(surface_parser: SurfaceParser) -> void:
    self.surface_parser = surface_parser


func _process(_delta: float) -> void:
    var is_inspector_open: bool = Sc.gui.hud.get_is_inspector_panel_open()
    if is_inspector_open != was_inspector_open:
        was_inspector_open = is_inspector_open
        update()


func _draw() -> void:
    for surface in surface_parser.all_surfaces:
        _draw_surface(surface)


func _draw_surface(surface: Surface) -> void:
    var color := color_params.get_color()
    color.a = \
            alpha_with_inspector_open if \
            was_inspector_open else \
            alpha_with_inspector_closed
    Sc.draw.draw_surface(
            self,
            surface,
            color)
