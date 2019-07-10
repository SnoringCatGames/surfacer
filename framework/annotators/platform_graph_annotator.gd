extends Node2D
class_name PlatformGraphAnnotator

const PlatformGraphInterSurfaceEdgesAnnotator = preload("res://framework/annotators/platform_graph_inter_surface_edges_annotator.gd")
const PlatformGraphSurfacesAnnotator = preload("res://framework/annotators/platform_graph_surfaces_annotator.gd")
const GridIndicesAnnotator = preload("res://framework/annotators/grid_indices_annotator.gd")

var graph: PlatformGraph
var platform_graph_inter_surface_edges_annotator: PlatformGraphInterSurfaceEdgesAnnotator
var platform_graph_surfaces_annotator: PlatformGraphSurfacesAnnotator
var grid_indices_annotator: GridIndicesAnnotator

func _init(graph: PlatformGraph) -> void:
    self.graph = graph
    platform_graph_inter_surface_edges_annotator = \
            PlatformGraphInterSurfaceEdgesAnnotator.new(graph)
    platform_graph_surfaces_annotator = PlatformGraphSurfacesAnnotator.new(graph.surface_parser)
    grid_indices_annotator = GridIndicesAnnotator.new(graph)

func _enter_tree() -> void:
    add_child(platform_graph_inter_surface_edges_annotator)
#    add_child(platform_graph_surfaces_annotator)
    add_child(grid_indices_annotator)

func check_for_update() -> void:
    pass
