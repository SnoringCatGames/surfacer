# This class records some state for failed edge calculations, including why
# the calculation failed.
class_name FailedEdgeAttempt
extends EdgeAttempt

var jump_land_positions: JumpLandPositions

# WaypointValidity
var waypoint_validity := WaypointValidity.UNKNOWN

var is_broad_phase_failure: bool

func _init( \
        jump_land_positions: JumpLandPositions = null, \
        edge_result_metadata: EdgeCalcResultMetadata = null, \
        calculator = null \
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
                EdgeCalcResultType.get_string(edge_calc_result_type), \
                EdgeType.get_string(edge_type), \
                WaypointValidity.get_string(waypoint_validity), \
                str(jump_land_positions.jump_position.target_point), \
                str(jump_land_positions.land_position.target_point), \
            ]

func load_from_json_object( \
        json_object: Dictionary, \
        context: Dictionary) -> void:
    _load_edge_attempt_state_from_json_object(json_object, context)
    jump_land_positions = context.id_to_jump_land_positions[json_object.p]
    waypoint_validity = json_object.w
    is_broad_phase_failure = EdgeCalcResultType.get_is_broad_phase_failure( \
            edge_calc_result_type)

func to_json_object() -> Dictionary:
    var json_object := {
        p = jump_land_positions.get_instance_id(),
        w = waypoint_validity,
    }
    _edge_attempt_state_to_json_object(json_object)
    return json_object
