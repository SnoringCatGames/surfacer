extends Node2D
class_name PlatformGraphEdgesAnnotator

# Dictionary<Surface, Array<PlatformGraphEdge>>
var edges: Dictionary

func _init(edges: Dictionary) -> void:
    self.edges = edges

func _draw() -> void:
    # FIXME
    pass
