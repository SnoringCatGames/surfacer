extends Node2D
class_name SurfacesAnnotator

var surface_parser: SurfaceParser

func _init(surface_parser: SurfaceParser) -> void:
    self.surface_parser = surface_parser

func _draw() -> void:
    _draw_surfaces(surface_parser.floors)
    _draw_surfaces(surface_parser.ceilings)
    _draw_surfaces(surface_parser.right_walls)
    _draw_surfaces(surface_parser.left_walls)

func _draw_surfaces(surfaces: Array) -> void:
    var color: Color
    for surface in surfaces:
        color = Color.from_hsv(randf(), 0.9, 0.9, 0.2)
        DrawUtils.draw_surface(self, surface, color)
