extends Node2D
class_name PlatformGraphEdgesAnnotator

const TRAJECTORY_WIDTH := 1.0

const CONSTRAINT_RADIUS := 4.0 * TRAJECTORY_WIDTH

# Dictionary<Surface, Array<PlatformGraphEdge>>
var edges: Dictionary

func _init(edges: Dictionary) -> void:
    self.edges = edges

func _draw() -> void:
    var hue: float
    var trajectory_color: Color
    var constraint_color: Color
    
    # Iterate over all surfaces.
    for surface in edges:
        # Iterate over all edges from this surface.
        for edge in edges[surface]:
            hue = randf()
            trajectory_color = Color.from_hsv(hue, 0.6, 0.9, 0.5)
            constraint_color = Color.from_hsv(hue, 0.6, 0.9, 0.3)
            
            draw_polyline(edge.instructions.frame_positions, trajectory_color, TRAJECTORY_WIDTH)
            
            for constraint_position in edge.instructions.constraint_positions:
                DrawUtils.draw_empty_circle(self, constraint_position, CONSTRAINT_RADIUS, \
                        constraint_color, TRAJECTORY_WIDTH, 4.0)
