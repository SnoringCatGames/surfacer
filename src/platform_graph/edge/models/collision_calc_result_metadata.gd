class_name CollisionCalcResultMetadata
extends Reference
# Metadata that captures internal calculation information for a single
# collision in order to help with debugging.


var step_start_position := Vector2.INF
var step_start_surface_position := Vector2.INF
var step_start_surface_normal := Vector2.INF

var step_end_position := Vector2.INF
var step_end_surface_position := Vector2.INF
var step_end_surface_normal := Vector2.INF

var collider_shape: Shape2D
var collider_rotation: float
var collider_is_rotated_90_degrees: bool
var collider_half_width_height := Vector2.INF
var margin: float

var frame_start_position := Vector2.INF
var frame_end_position := Vector2.INF
var frame_previous_position := Vector2.INF

var collision: SurfaceCollision


func _init(
        edge_calc_params = null,
        step_calc_params = null,
        horizontal_step = null) -> void:
    if edge_calc_params != null:
        self.collider_shape = edge_calc_params.movement_params.collider_shape
        self.collider_rotation = \
                edge_calc_params.movement_params.collider_rotation
        self.collider_is_rotated_90_degrees = \
                edge_calc_params.movement_params.collider_is_rotated_90_degrees
        self.collider_half_width_height = \
                edge_calc_params.movement_params.collider_half_width_height
        self.margin = edge_calc_params.movement_params \
                .collision_margin_for_edge_calculations
    
    if step_calc_params != null:
        self.step_start_position = step_calc_params.start_waypoint.position
        if step_calc_params.start_waypoint.surface != null:
            self.step_start_surface_position = \
                    step_calc_params.start_waypoint.surface.bounding_box \
                            .position
            self.step_start_surface_normal = \
                    step_calc_params.start_waypoint.surface.normal
        else:
            self.step_start_surface_position = Vector2.INF
            self.step_start_surface_normal = Vector2.INF
        
        self.step_end_position = step_calc_params.end_waypoint.position
        if step_calc_params.end_waypoint.surface != null:
            self.step_end_surface_position = \
                    step_calc_params.end_waypoint.surface.bounding_box \
                            .position
            self.step_end_surface_normal = \
                    step_calc_params.end_waypoint.surface.normal
        else:
            self.step_end_surface_position = Vector2.INF
            self.step_end_surface_normal = Vector2.INF
    
    if horizontal_step != null:
        self.frame_start_position = horizontal_step.position_step_start
        self.frame_previous_position = horizontal_step.position_step_start


func record_collision(
        position_start: Vector2,
        displacement: Vector2,
        surface_collision: SurfaceCollision) -> void:
    self.frame_previous_position = self.frame_start_position
    self.frame_start_position = position_start
    self.frame_end_position = position_start + displacement
    self.collision = surface_collision
