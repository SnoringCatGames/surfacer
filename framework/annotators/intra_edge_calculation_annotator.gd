extends Node2D
class_name IntraEdgeCalculationAnnotator

const TRAJECTORY_WIDTH := 1.0
const COLLISION_X_WIDTH_HEIGHT := Vector2(16.0, 16.0)
const COLLISION_X_STROKE_WIDTH := 3.0
const COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH := 1.0
const CONSTRAINT_WIDTH := 2.0
const CONSTRAINT_RADIUS := 3.0 * CONSTRAINT_WIDTH

const STEP_HUE_START := 0.11
const STEP_HUE_END := 0.61
const COLLISION_HUE := 0.0

var collision_color := Color.from_hsv(COLLISION_HUE, 0.6, 0.9, 0.5)

var graph: PlatformGraph

func _init(graph: PlatformGraph) -> void:
    self.graph = graph

func _draw() -> void:
    var step_attempts: Array
    var step_attempts_count: float
    var step_attempt: MovementCalcStepDebugState
    var collision: SurfaceCollision
    var step_hue: float
    var step_color: Color

    var edge_calc_debug_state = graph.debug_state["edge_calc_debug_state"]
    if edge_calc_debug_state != null:
        # Iterate over all edge calculations.
        for edge_attempt in edge_calc_debug_state:
            step_attempts = edge_attempt.step_attempts
            step_attempts_count = step_attempts.size()
            
            # Iterate over the calculation steps for this edge.
            for step_index in range(step_attempts_count):
                step_attempt = step_attempts[step_index]

                # Hue transitions evenly from start to end.
                step_hue = STEP_HUE_START + (STEP_HUE_END - STEP_HUE_START) * (step_index / (step_attempts_count - 1.0))
                step_color = Color.from_hsv(step_hue, 0.6, 0.9, 0.5)

                # Draw the step trajectory.
                draw_polyline(step_attempt.frame_positions, step_color, TRAJECTORY_WIDTH)

                # Draw the step end points.
                DrawUtils.draw_circle_outline(self, step_attempt.start_constraint.position, \
                        CONSTRAINT_RADIUS, step_color, CONSTRAINT_WIDTH, 4.0)
                DrawUtils.draw_circle_outline(self, step_attempt.end_constraint.position, \
                        CONSTRAINT_RADIUS, step_color, CONSTRAINT_WIDTH, 4.0)
                
                collision = step_attempt.collision
                
                # Draw any collision.
                if collision != null:
                    # Draw an X at the actual point of collision.
                    DrawUtils.draw_x(self, collision.position, COLLISION_X_WIDTH_HEIGHT.x, \
                            COLLISION_X_WIDTH_HEIGHT.y, collision_color, COLLISION_X_STROKE_WIDTH)
                    
                    # Draw an outline of the player's collision boundary at the point of collision.
                    DrawUtils.draw_shape_outline(self, collision.player_position, \
                            edge_attempt.movement_params.collider_shape, \
                            edge_attempt.movement_params.collider_rotation, collision_color, \
                            COLLISION_PLAYER_BOUNDARY_STROKE_WIDTH)
