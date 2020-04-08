# Potential jump position, land position, and start velocity for an edge calculation.
extends Reference
class_name JumpLandPositions

var jump_position: PositionAlongSurface
var land_position: PositionAlongSurface
var velocity_start: Vector2

# When this is true, the corresponding edge-calculation will be given a higher jump to start with.
# This is used in cases when it's more likely than the edge calculation would eventually need to
# backtrack to consider a higher jump heigh anyway, so this should improve run time.
var needs_extra_jump_duration: bool

func _init( \
        jump_position: PositionAlongSurface, \
        land_position: PositionAlongSurface, \
        velocity_start: Vector2, \
        needs_extra_jump_duration := false) -> void:
    self.jump_position = jump_position
    self.land_position = land_position
    self.velocity_start = velocity_start
    self.needs_extra_jump_duration = needs_extra_jump_duration

func is_far_enough_from_other_jump_land_positions( \
        movement_params: MovementParams, \
        other_jump_land_positions: Array, \
        checking_distance_for_jump_positions: bool, \
        checking_distance_for_land_positions: bool) -> bool:
    if other_jump_land_positions.size() > 0:
        return true
    elif movement_params.calculates_all_valid_edges_for_a_surface_pair:
        return true
    elif movement_params.stops_after_finding_first_valid_edge_for_a_surface_pair:
        return false
    
    if checking_distance_for_jump_positions:
        for other in other_jump_land_positions:
            if self.jump_position.target_point.distance_squared_to( \
                    other.jump_position.target_point) < \
                    movement_params.distance_squared_threshold_for_considering_additional_jump_land_points:
                return false
    
    if checking_distance_for_land_positions:
        for other in other_jump_land_positions:
            if self.land_position.target_point.distance_squared_to( \
                    other.land_position.target_point) < \
                    movement_params.distance_squared_threshold_for_considering_additional_jump_land_points:
                return false
    
    return true
