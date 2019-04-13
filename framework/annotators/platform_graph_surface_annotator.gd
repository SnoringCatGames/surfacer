extends Node2D
class_name PlatformGraphSurfaceAnnotator

var graph: PlatformGraph

func _init(graph: PlatformGraph) -> void:
    self.graph = graph

func _draw() -> void:
    _draw_surfaces(graph.nodes.floors, Utils.UP)
    _draw_surfaces(graph.nodes.ceilings, Utils.DOWN)
    _draw_surfaces(graph.nodes.right_walls, Utils.LEFT)
    _draw_surfaces(graph.nodes.left_walls, Utils.RIGHT)

func _draw_surfaces(surfaces: Array, normal: Vector2) -> void:
    var color: Color
    for surface in surfaces:
        color = Color.from_hsv(randf(), 0.9, 0.9, 0.2)
        Utils.draw_surface(self, surface, normal, color)
