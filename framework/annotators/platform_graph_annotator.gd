extends Node2D
class_name PlatformGraphAnnotator

const PlatformGraphEdgesAnnotator = preload("res://framework/annotators/platform_graph_edges_annotator.gd")
const PlatformGraphNodesAnnotator = preload("res://framework/annotators/platform_graph_nodes_annotator.gd")
const GridIndicesAnnotator = preload("res://framework/annotators/grid_indices_annotator.gd")

var graph: PlatformGraph
var platform_graph_edges_annotator: PlatformGraphEdgesAnnotator
var platform_graph_nodes_annotator: PlatformGraphNodesAnnotator
var grid_indices_annotator: GridIndicesAnnotator

func _init(graph: PlatformGraph) -> void:
    self.graph = graph
    platform_graph_edges_annotator = PlatformGraphEdgesAnnotator.new(graph.edges)
    platform_graph_nodes_annotator = PlatformGraphNodesAnnotator.new(graph.surface_parser)
    grid_indices_annotator = GridIndicesAnnotator.new(graph)

func _enter_tree() -> void:
    add_child(platform_graph_edges_annotator)
#    add_child(platform_graph_nodes_annotator)
    add_child(grid_indices_annotator)

func check_for_update() -> void:
    pass
