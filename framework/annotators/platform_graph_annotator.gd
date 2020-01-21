extends Node2D
class_name PlatformGraphAnnotator

const JumpFromSurfaceToSurfaceEdgesAnnotator := preload("res://framework/annotators/jump_from_surface_to_surface_edges_annotator.gd")
const SurfacesAnnotator := preload("res://framework/annotators/surfaces_annotator.gd")
const GridIndicesAnnotator := preload("res://framework/annotators/grid_indices_annotator.gd")

var graph: PlatformGraph
var jump_from_surface_to_surface_edges_annotator: JumpFromSurfaceToSurfaceEdgesAnnotator
var surfaces_annotator: SurfacesAnnotator
var grid_indices_annotator: GridIndicesAnnotator

func _init(graph: PlatformGraph) -> void:
    self.graph = graph
    jump_from_surface_to_surface_edges_annotator = \
            JumpFromSurfaceToSurfaceEdgesAnnotator.new(graph)
    surfaces_annotator = SurfacesAnnotator.new(graph.surface_parser)
    grid_indices_annotator = GridIndicesAnnotator.new(graph)

func _enter_tree() -> void:
    add_child(jump_from_surface_to_surface_edges_annotator)
#    add_child(surfaces_annotator)
#    add_child(grid_indices_annotator)

func check_for_update() -> void:
    pass
