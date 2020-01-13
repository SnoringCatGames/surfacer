extends Node2D
class_name InterSurfaceEdgesAnnotator

const EdgeCalculationAnnotator := preload("res://framework/annotators/edge_calculation_annotator.gd")

const TRAJECTORY_WIDTH := 1.0

const CONSTRAINT_WIDTH := 2.0
const CONSTRAINT_RADIUS := 3.0 * CONSTRAINT_WIDTH
const START_RADIUS := 1.5 * CONSTRAINT_WIDTH

const HORIZONTAL_INSTRUCTION_START_LENGTH := 9
const HORIZONTAL_INSTRUCTION_START_STROKE_WIDTH := 1
const HORIZONTAL_INSTRUCTION_END_LENGTH := 9
const HORIZONTAL_INSTRUCTION_END_STROKE_WIDTH := 1
const VERTICAL_INSTRUCTION_END_LENGTH := 11
const VERTICAL_INSTRUCTION_END_STROKE_WIDTH := 1

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
                
                hue = randf()
                discrete_trajectory_color = Color.from_hsv(hue, 0.6, 0.9, 0.5)
                continuous_trajectory_color = Color.from_hsv(hue, 0.6, 0.5, 0.5)
                constraint_color = Color.from_hsv(hue, 0.6, 0.9, 0.3)
                instruction_start_stop_color = Color.from_hsv(hue, 0.1, 0.99, 0.8)
                
                # Draw the trajectory (as approximated via discrete time steps during instruction 
                # test calculations).
                draw_polyline(edge.instructions.frame_discrete_positions_from_test, \
                        discrete_trajectory_color, TRAJECTORY_WIDTH)
                
                # Draw the trajectory (as calculated via continuous equations of motion during step
                # calculations).
                draw_polyline(edge.instructions.frame_continous_positions_from_steps, \
                        continuous_trajectory_color, TRAJECTORY_WIDTH)
                
                # Draw all constraints in this edge.
                for constraint_position in edge.instructions.constraint_positions:
                    DrawUtils.draw_circle_outline(self, constraint_position, CONSTRAINT_RADIUS, \
                            constraint_color, CONSTRAINT_WIDTH, 4.0)
                DrawUtils.draw_circle_outline(self, edge.start, START_RADIUS, \
                        constraint_color, CONSTRAINT_WIDTH, 4.0)
                
                # Draw the positions where horizontal instructions start.
                for i in range(0, edge.instructions.horizontal_instruction_start_positions.size()):
                    position_start = edge.instructions.horizontal_instruction_start_positions[i]
                    
                    # Draw a plus for the instruction start.
                    DrawUtils.draw_plus(self, position_start, \
                            HORIZONTAL_INSTRUCTION_START_LENGTH, \
                            HORIZONTAL_INSTRUCTION_START_LENGTH, instruction_start_stop_color, \
                            HORIZONTAL_INSTRUCTION_START_STROKE_WIDTH)
                
                # Draw the positions where horizontal instructions end.
                for i in range(0, edge.instructions.horizontal_instruction_end_positions.size()):
                    position_end = edge.instructions.horizontal_instruction_end_positions[i]
                            
                    # Draw a minus for the instruction end.
                    self.draw_line( \
                            position_end + Vector2(-HORIZONTAL_INSTRUCTION_START_LENGTH / 2, 0), \
                            position_end + Vector2(HORIZONTAL_INSTRUCTION_START_LENGTH / 2, 0), \
                            instruction_start_stop_color, \
                            HORIZONTAL_INSTRUCTION_START_STROKE_WIDTH)
                
                # Draw the position where the vertical instruction ends (draw an asterisk).
                position_end = edge.instructions.jump_instruction_end_position
                DrawUtils.draw_asterisk(self, position_start, \
                        VERTICAL_INSTRUCTION_END_LENGTH, VERTICAL_INSTRUCTION_END_LENGTH, \
                        instruction_start_stop_color, VERTICAL_INSTRUCTION_END_STROKE_WIDTH)
