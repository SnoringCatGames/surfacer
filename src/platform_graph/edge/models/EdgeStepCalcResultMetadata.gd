# Metadata that captures internal calculation information for a single edge
# horizontal step in order to help with debugging.
class_name EdgeStepCalcResultMetadata
extends Reference

var edge_result_metadata: EdgeCalcResultMetadata

var index: int

# Array<EdgeStepCalcResultMetadata>
var children_step_attempts := []

var step_calc_params: EdgeStepCalcParams

var edge_step_calc_result_type := EdgeStepCalcResultType.UNKNOWN

# Array<Waypoint>
var upcoming_waypoints: Array

var previous_out_of_reach_waypoint: Waypoint

var step: EdgeStep

var collision_result_metadata: CollisionCalcResultMetadata

func _init(
        edge_result_metadata: EdgeCalcResultMetadata,
        parent_step_result_metadata: EdgeStepCalcResultMetadata,
        step_calc_params: EdgeStepCalcParams,
        previous_out_of_reach_waypoint: Waypoint) -> void:
    self.edge_result_metadata = edge_result_metadata
    self.step_calc_params = step_calc_params
    self.previous_out_of_reach_waypoint = previous_out_of_reach_waypoint
    self.index = edge_result_metadata.total_step_count
    
    # Record this on its parent.
    if parent_step_result_metadata != null:
        parent_step_result_metadata.children_step_attempts.push_back(self)
    else:
        edge_result_metadata.children_step_attempts.push_back(self)
    edge_result_metadata.total_step_count += 1

func get_start() -> Waypoint:
    return step_calc_params.start_waypoint as Waypoint

func get_end() -> Waypoint:
    return step_calc_params.end_waypoint as Waypoint

func get_result_type_string() -> String:
    return EdgeStepCalcResultType.get_string(edge_step_calc_result_type)

func get_description_list() -> Array:
    return EdgeStepCalcResultType.to_description_list(
            edge_step_calc_result_type)

func get_is_backtracking() -> bool:
    return previous_out_of_reach_waypoint != null

func get_replaced_a_fake() -> bool:
    return step_calc_params.end_waypoint.replaced_a_fake
