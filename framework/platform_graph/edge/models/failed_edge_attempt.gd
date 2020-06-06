# FIXME: ----------- doc
extends Reference
class_name FailedEdgeAttempt

var origin_surface: Surface

var destination_surface: Surface

var start: Vector2

var end: Vector2

var velocity_start: Vector2

# EdgeType
var edge_type := EdgeType.UNKNOWN

# EdgeCalcResultType
var edge_calc_result_type := EdgeCalcResultType.UNKNOWN

# WaypointValidity
var waypoint_validity := WaypointValidity.UNKNOWN

var needs_extra_jump_duration: bool
var needs_extra_wall_land_horizontal_speed: bool

var is_broad_phase_failure: bool

var calculator

func _init( \
        jump_land_positions: JumpLandPositions, \
        edge_result_metadata: EdgeCalcResultMetadata, \
        edge_type: int, \
        calculator) -> void:
    self.origin_surface = jump_land_positions.jump_position.surface
    self.destination_surface = jump_land_positions.land_position.surface
    self.start = jump_land_positions.jump_position.target_point
    self.end = jump_land_positions.land_position.target_point
    self.velocity_start = jump_land_positions.velocity_start
    self.edge_type = edge_type
    self.edge_calc_result_type = edge_result_metadata.edge_calc_result_type
    self.waypoint_validity = edge_result_metadata.waypoint_validity
    self.needs_extra_jump_duration = \
            jump_land_positions.needs_extra_jump_duration
    self.needs_extra_wall_land_horizontal_speed = \
            jump_land_positions.needs_extra_wall_land_horizontal_speed
    self.calculator = calculator
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
                str(start), \
                str(end), \
            ]
