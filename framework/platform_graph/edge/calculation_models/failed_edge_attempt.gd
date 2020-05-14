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

func _init(
        origin_surface: Surface, \
        destination_surface: Surface, \
        start: Vector2, \
        end: Vector2, \
        velocity_start: Vector2, \
        edge_type: int, \
        edge_calc_result_type: int, \
        waypoint_validity: int) -> void:
    self.origin_surface = origin_surface
    self.destination_surface = destination_surface
    self.start = start
    self.end = end
    self.velocity_start = velocity_start
    self.edge_type = edge_type
    self.edge_calc_result_type = edge_calc_result_type
    self.waypoint_validity = waypoint_validity

func to_string() -> String:
    return "FailedEdgeAttempt{ " + \
                "%s, " + \
                "edge_type: %s, " + \
                "waypoint_validity: %s, " + \
                "start: %s, " + \
                "end: %s " + \
            "}" % \
            [ \
                EdgeCalcResultType.get_result_string(edge_calc_result_type), \
                EdgeType.get_type_string(edge_type), \
                WaypointValidity.get_validity_string(waypoint_validity), \
                str(start), \
                str(end), \
            ]
