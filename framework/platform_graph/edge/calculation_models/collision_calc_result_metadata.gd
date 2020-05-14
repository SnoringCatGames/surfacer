# Metadata that captures internal calculation information for a single collision in order to help
# with debugging.
extends Reference
class_name CollisionCalcResultMetadata

var step_start_position := Vector2.INF
var step_start_surface_position := Vector2.INF
var step_start_surface_normal := Vector2.INF

var step_end_position := Vector2.INF
var step_end_surface_position := Vector2.INF
var step_end_surface_normal := Vector2.INF

var step_start_time: float
var step_end_time: float

var collider_half_width_height := Vector2.INF
var margin: float

var frame_current_time: float
var frame_motion := Vector2.INF
var frame_start_position := Vector2.INF
var frame_end_position := Vector2.INF
var frame_previous_position := Vector2.INF
var frame_start_min_coordinates := Vector2.INF
var frame_start_max_coordinates := Vector2.INF
var frame_end_min_coordinates := Vector2.INF
var frame_end_max_coordinates := Vector2.INF
var frame_previous_min_coordinates := Vector2.INF
var frame_previous_max_coordinates := Vector2.INF

# Array<Vector2>
var intersection_points := []
# Array<float>
var collision_ratios := []

var collision: SurfaceCollision

func _init( \
        overall_calc_params = null, \
        step_calc_params = null, \
        horizontal_step = null) -> void:
    if overall_calc_params != null:
        self.collider_half_width_height = \
                overall_calc_params.movement_params.collider_half_width_height
        self.margin = overall_calc_params.shape_query_params.margin
    
    if step_calc_params != null:
        self.step_start_position = step_calc_params.start_waypoint.position
        if step_calc_params.start_waypoint.surface != null:
            self.step_start_surface_position = \
                    step_calc_params.start_waypoint.surface.bounding_box.position
            self.step_start_surface_normal = step_calc_params.start_waypoint.surface.normal
        else:
            self.step_start_surface_position = Vector2.INF
            self.step_start_surface_normal = Vector2.INF
        
        self.step_end_position = step_calc_params.end_waypoint.position
        if step_calc_params.end_waypoint.surface != null:
            self.step_end_surface_position = \
                    step_calc_params.end_waypoint.surface.bounding_box.position
            self.step_end_surface_normal = step_calc_params.end_waypoint.surface.normal
        else:
            self.step_end_surface_position = Vector2.INF
            self.step_end_surface_normal = Vector2.INF
    
    if horizontal_step != null:
        self.step_start_time = horizontal_step.time_step_start
        self.step_end_time = horizontal_step.time_step_end
        
        self.frame_start_position = horizontal_step.position_step_start
        self.frame_previous_position = horizontal_step.position_step_start

func get_position_at_collision_ratio_index(index: int) -> Vector2:
    return frame_start_position + frame_motion * collision_ratios[index]
