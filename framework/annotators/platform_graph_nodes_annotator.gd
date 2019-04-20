extends Node2D
class_name PlatformGraphNodesAnnotator

var nodes: PlatformGraphNodes

func _init(nodes: PlatformGraphNodes) -> void:
    self.nodes = nodes

func _draw() -> void:
    _draw_surfaces(nodes.floors)
    _draw_surfaces(nodes.ceilings)
    _draw_surfaces(nodes.right_walls)
    _draw_surfaces(nodes.left_walls)

func _draw_surfaces(surfaces: Array) -> void:
    var color: Color
    for surface in surfaces:
        color = Color.from_hsv(randf(), 0.9, 0.9, 0.2)
        DrawUtils.draw_surface(self, surface, color)
