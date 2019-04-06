extends Node
class_name Level

const PlatformGraph = preload("res://framework/platform_graph/platform_graph.gd")
const PlatformGraphAnnotator = preload("res://framework/platform_graph/platform_graph_annotator.gd")

func _ready() -> void:
    var global := get_node("/root/Global")
    var graph := PlatformGraph.new($WallsAndFloors, global.player_types)
    var annotator := PlatformGraphAnnotator.new(graph)
    add_child(annotator)
