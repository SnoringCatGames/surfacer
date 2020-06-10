extends Reference
class_name InterSurfaceEdgesResult

var origin_surface: Surface
var destination_surface: Surface
var edge_type := EdgeType.UNKNOWN
# Array<JumpLandPositions>
var all_jump_land_positions := []
# Array<FailedEdgeAttempt>
var failed_edge_attempts := []
# Array<Edge>
var valid_edges := []
# Array<EdgeCalcResult>
var edge_calc_results := []

func _init( \
        origin_surface: Surface, \
        destination_surface: Surface, \
        edge_type: int, \
        all_jump_land_positions: Array) -> void:
    self.origin_surface = origin_surface
    self.destination_surface = destination_surface
    self.edge_type = edge_type
    self.all_jump_land_positions = all_jump_land_positions
