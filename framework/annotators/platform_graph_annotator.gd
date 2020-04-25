extends Node2D
class_name PlatformGraphAnnotator

var graph: PlatformGraph
var inter_surface_edges_annotator: InterSurfaceEdgesAnnotator
var surfaces_annotator: SurfacesAnnotator
var grid_indices_annotator: GridIndicesAnnotator

func _init(graph: PlatformGraph) -> void:
    self.graph = graph
    inter_surface_edges_annotator = \
            InterSurfaceEdgesAnnotator.new(graph)
    surfaces_annotator = SurfacesAnnotator.new(graph.surface_parser)
    grid_indices_annotator = GridIndicesAnnotator.new(graph)

func _enter_tree() -> void:
    add_child(inter_surface_edges_annotator)
#    add_child(surfaces_annotator)
#    add_child(grid_indices_annotator)

func check_for_update() -> void:
    pass
