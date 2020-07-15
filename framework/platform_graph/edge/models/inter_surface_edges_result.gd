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

func merge(other) -> void:
    Utils.concat( \
            self.all_jump_land_positions, \
            other.all_jump_land_positions)
    Utils.concat( \
            self.failed_edge_attempts, \
            other.failed_edge_attempts)
    Utils.concat( \
            self.valid_edges, \
            other.valid_edges)
    Utils.concat( \
            self.edge_calc_results, \
            other.edge_calc_results)
