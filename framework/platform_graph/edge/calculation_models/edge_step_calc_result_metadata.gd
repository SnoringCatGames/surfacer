# Metadata that captures internal calculation information for a single edge horizontal step in
# order to help with debugging.
extends Reference
class_name EdgeStepCalcResultMetadata

var edge_result_metadata: EdgeCalcResultMetadata

var index: int

# Array<EdgeStepCalcResultMetadata>
var children_step_attempts := []

var edge_step_calc_result_type := EdgeStepCalcResultType.UNKNOWN

# Array<Waypoint>
var upcoming_waypoints: Array

var previous_out_of_reach_waypoint: Waypoint

var step: MovementCalcStep

var collision_result_metadata: CollisionCalcResultMetadata

func _init( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        parent_step_result_metadata: EdgeStepCalcResultMetadata, \
        previous_out_of_reach_waypoint: Waypoint) -> void:
    self.edge_result_metadata = edge_result_metadata
    self.previous_out_of_reach_waypoint = previous_out_of_reach_waypoint
    self.index = edge_result_metadata.total_step_count
    
    # Record this on its parent.
    if parent_step_result_metadata != null:
        parent_step_result_metadata.children_step_attempts.push_back(self)
    else:
        edge_result_metadata.children_step_attempts.push_back(self)
    edge_result_metadata.total_step_count += 1
