# This class records some state for failed edge calculations, including why
# the calculation failed.
extends EdgeAttempt
class_name FailedEdgeAttempt

var jump_land_positions: JumpLandPositions

# WaypointValidity
var waypoint_validity := WaypointValidity.UNKNOWN

var is_broad_phase_failure: bool

func _init( \
        jump_land_positions: JumpLandPositions, \
        edge_result_metadata: EdgeCalcResultMetadata, \
        calculator \
        ).( \
        calculator.edge_type, \
        edge_result_metadata.edge_calc_result_type, \
        jump_land_positions.jump_position, \
        jump_land_positions.land_position, \
        jump_land_positions.velocity_start, \
        jump_land_positions.needs_extra_jump_duration, \
        jump_land_positions.needs_extra_wall_land_horizontal_speed, \
        calculator \
        ) -> void:
    self.jump_land_positions = jump_land_positions
    self.edge_calc_result_type = edge_result_metadata.edge_calc_result_type
    self.waypoint_validity = edge_result_metadata.waypoint_validity
    self.is_broad_phase_failure = \
            EdgeCalcResultType.get_is_broad_phase_failure( \
                    edge_calc_result_type)

func to_string() -> String:
    return "FailedEdgeAttempt{ " + \
                "%s, " + \
                "edge_type: %s, " + \
                "waypoint_validity: %s, " + \
                "start: %s, " + \
                "end: %s " + \
            "}" % \
            [ \
                EdgeCalcResultType.get_type_string(edge_calc_result_type), \
                EdgeType.get_type_string(edge_type), \
                WaypointValidity.get_type_string(waypoint_validity), \
                str(jump_land_positions.jump_position.target_point), \
                str(jump_land_positions.land_position.target_point), \
            ]
