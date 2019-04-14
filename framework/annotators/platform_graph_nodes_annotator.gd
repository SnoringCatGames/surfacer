extends Node2D
class_name PlatformGraphNodesAnnotator

var graph: PlatformGraph

func _init(graph: PlatformGraph) -> void:
    self.graph = graph

func _draw() -> void:
    _draw_surfaces(graph.nodes.floors)
    _draw_surfaces(graph.nodes.ceilings)
    _draw_surfaces(graph.nodes.right_walls)
    _draw_surfaces(graph.nodes.left_walls)

func _draw_surfaces(surfaces: Array) -> void:
    var color: Color
    for surface in surfaces:
        color = Color.from_hsv(randf(), 0.9, 0.9, 0.2)
        DrawUtils.draw_surface(self, surface, color)
