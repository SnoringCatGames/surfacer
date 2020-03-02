extends Node2D
class_name InterSurfaceEdgesAnnotator

const EdgeCalculationAnnotator := preload("res://framework/annotators/edge_calculation_annotator.gd")

var graph: PlatformGraph
var intra_edge_calc_annotator: EdgeCalculationAnnotator

func _init(graph: PlatformGraph) -> void:
    self.graph = graph
    self.intra_edge_calc_annotator = EdgeCalculationAnnotator.new(graph)

func _enter_tree() -> void:
    add_child(intra_edge_calc_annotator)

func _draw() -> void:
    var hue: float
    var discrete_trajectory_color: Color
    var continuous_trajectory_color: Color
    var constraint_color: Color
    var instruction_start_stop_color: Color
    var edge: Edge
    var position_start: Vector2
    var position_end: Vector2
    
    # Iterate over all surfaces.
    for surface in graph.surfaces_to_outbound_nodes:
        # Iterate over all nodes from this surface.
        for node_start in graph.surfaces_to_outbound_nodes[surface]:
            # Iterate over all edges from this node.
            for node_end in graph.nodes_to_nodes_to_edges[node_start]:
                edge = graph.nodes_to_nodes_to_edges[node_start][node_end]
                
                # Skip intra-surface edges. They aren't as interesting to render.
                if edge is IntraSurfaceEdge:
                    continue
                
                DrawUtils.draw_edge(self, edge, true, true, true)
