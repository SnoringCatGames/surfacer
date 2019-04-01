extends Node
class_name Level

const PlatformGraph = preload("platform_graph.gd")
const PlatformGraphAnnotator = preload("platform_graph_annotator.gd")

func _ready() -> void:
    var graph := PlatformGraph.new($WallsAndFloors)
    var annotator := PlatformGraphAnnotator.new(graph)
    add_child(annotator)
