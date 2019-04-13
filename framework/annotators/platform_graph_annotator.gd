extends Node2D
class_name PlatformGraphAnnotator

const PlatformGraphSurfaceAnnotator = preload("res://framework/annotators/platform_graph_surface_annotator.gd")
const GridIndicesAnnotator = preload("res://framework/annotators/grid_indices_annotator.gd")

var graph: PlatformGraph
var platform_graph_surface_annotator: PlatformGraphSurfaceAnnotator
var grid_indices_annotator: GridIndicesAnnotator

func _init(graph: PlatformGraph) -> void:
    self.graph = graph
    platform_graph_surface_annotator = PlatformGraphSurfaceAnnotator.new(graph)
    grid_indices_annotator = GridIndicesAnnotator.new(graph)

func _enter_tree() -> void:
    add_child(platform_graph_surface_annotator)
    add_child(grid_indices_annotator)

func check_for_update() -> void:
    pass
