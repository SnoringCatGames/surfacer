# This class records some state for failed edge calculations, including why
# the calculation failed.
extends Reference
class_name FailedEdgeAttempt

var jump_land_positions: JumpLandPositions

# EdgeType
var edge_type := EdgeType.UNKNOWN

# EdgeCalcResultType
var edge_calc_result_type := EdgeCalcResultType.UNKNOWN

# WaypointValidity
var waypoint_validity := WaypointValidity.UNKNOWN

var is_broad_phase_failure: bool

var calculator

var start: Vector2 setget ,_get_start
var end: Vector2 setget ,_get_end
var origin_surface: Surface setget ,_get_origin_surface
var destination_surface: Surface setget ,_get_destination_surface

func _init( \
        jump_land_positions: JumpLandPositions, \
        edge_result_metadata: EdgeCalcResultMetadata, \
        calculator) -> void:
    self.jump_land_positions = jump_land_positions
    self.edge_type = edge_type
    self.edge_calc_result_type = edge_result_metadata.edge_calc_result_type
    self.waypoint_validity = edge_result_metadata.waypoint_validity
    self.edge_type = calculator.edge_type
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
                str(jump_land_positions.jump_position.target_point), \
                str(jump_land_positions.land_position.target_point), \
            ]

func _get_start() -> Vector2:
    return jump_land_positions.jump_position.target_point

func _get_end() -> Vector2:
    return jump_land_positions.land_position.target_point

func _get_origin_surface() -> Surface:
    return jump_land_positions.jump_position.surface

func _get_destination_surface() -> Surface:
    return jump_land_positions.land_position.surface
