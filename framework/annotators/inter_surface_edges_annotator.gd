extends Node2D
class_name InterSurfaceEdgesAnnotator

const TRAJECTORY_WIDTH := 1.0

const CONSTRAINT_WIDTH := 2.0
const CONSTRAINT_RADIUS := 3.0 * CONSTRAINT_WIDTH
const START_RADIUS := 1.5 * CONSTRAINT_WIDTH

var graph: PlatformGraph

func _init(graph: PlatformGraph) -> void:
    self.graph = graph

func _draw() -> void:
    var hue: float
    var discrete_trajectory_color: Color
    var continuous_trajectory_color: Color
    var constraint_color: Color
    var edge: Edge
    
    # Iterate over all surfaces.
    for surface in graph.surfaces_to_nodes:
        # Iterate over all nodes from this surface.
        for node_start in graph.surfaces_to_nodes[surface]:
            # Iterate over all edges from this node.
            for node_end in graph.nodes_to_edges[node_start]:
                edge = graph.nodes_to_edges[node_start][node_end]
                
                # Skip intra-surface edges. They aren't as interesting to render.
                if edge is IntraSurfaceEdge:
                    continue
                
                hue = randf()
                discrete_trajectory_color = Color.from_hsv(hue, 0.6, 0.9, 0.5)
                continuous_trajectory_color = Color.from_hsv(hue, 0.6, 0.5, 0.5)
                constraint_color = Color.from_hsv(hue, 0.6, 0.9, 0.3)
                
                draw_polyline(edge.instructions.frame_discrete_positions, \
                        discrete_trajectory_color, TRAJECTORY_WIDTH)
                draw_polyline(edge.instructions.frame_continuous_positions, \
                        continuous_trajectory_color, TRAJECTORY_WIDTH)
                
                for constraint_position in edge.instructions.constraint_positions:
                    DrawUtils.draw_empty_circle(self, constraint_position, CONSTRAINT_RADIUS, \
                            constraint_color, CONSTRAINT_WIDTH, 4.0)
                
                DrawUtils.draw_empty_circle(self, edge.start.target_point, START_RADIUS, \
                        constraint_color, CONSTRAINT_WIDTH, 4.0)
