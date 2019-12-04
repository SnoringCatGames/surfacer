# State that captures internal calculation information for a single collision in order to help
# with debugging.
extends Reference
class_name MovementCalcCollisionDebugState

var step_start_position: Vector2
var step_start_surface_position: Vector2
var step_start_surface_normal: Vector2

var step_end_position: Vector2
var step_end_surface_position: Vector2
var step_end_surface_normal: Vector2

var step_start_time: float
var step_end_time: float

var collider_half_width_height: Vector2

var frame_current_time: float
var frame_motion: Vector2
var frame_start_position: Vector2
var frame_end_position: Vector2
var frame_previous_position: Vector2
var frame_start_min_coordinates: Vector2
var frame_start_max_coordinates: Vector2
var frame_end_min_coordinates: Vector2
var frame_end_max_coordinates: Vector2
var frame_previous_min_coordinates: Vector2
var frame_previous_max_coordinates: Vector2

# Array<Vector2>
var intersection_points := []
# Array<float>
var collision_ratios := []

func _init(overall_calc_params = null, step_calc_params = null, horizontal_step = null) -> void:
    if overall_calc_params != null:
        self.collider_half_width_height = \
                overall_calc_params.movement_params.collider_half_width_height
    
    if step_calc_params != null:
        self.step_start_position = step_calc_params.start_constraint.position
        self.step_start_surface_position = \
                step_calc_params.start_constraint.surface.bounding_box.position
        self.step_start_surface_normal = step_calc_params.start_constraint.surface.normal
        
        self.step_end_position = step_calc_params.end_constraint.position
        self.step_end_surface_position = step_calc_params.end_constraint.surface.bounding_box.position
        self.step_end_surface_normal = step_calc_params.end_constraint.surface.normal
    
    if horizontal_step != null:
        self.step_start_time = horizontal_step.time_step_start
        self.step_end_time = horizontal_step.time_step_end
        
        self.frame_start_position = horizontal_step.position_step_start
        self.frame_previous_position = horizontal_step.position_step_start
