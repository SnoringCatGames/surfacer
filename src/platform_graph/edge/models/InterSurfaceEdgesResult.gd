class_name InterSurfaceEdgesResult
extends Reference

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
    Gs.utils.concat( \
            self.all_jump_land_positions, \
            other.all_jump_land_positions)
    Gs.utils.concat( \
            self.failed_edge_attempts, \
            other.failed_edge_attempts)
    Gs.utils.concat( \
            self.valid_edges, \
            other.valid_edges)
    Gs.utils.concat( \
            self.edge_calc_results, \
            other.edge_calc_results)

static func merge_results_with_matching_destination_surfaces( \
        inter_surface_edges_results: Array) -> void:
    # Dictionary<Surface, InterSurfaceEdgesResult>
    var inter_surface_edges_results_set := {}
    var i := 0
    var old_result
    var new_result
    while i < inter_surface_edges_results.size():
        new_result = inter_surface_edges_results[i]
        if !inter_surface_edges_results_set.has( \
                new_result.destination_surface):
            inter_surface_edges_results_set[new_result.destination_surface] = \
                    new_result
        else:
            old_result = inter_surface_edges_results_set[ \
                    new_result.destination_surface]
            inter_surface_edges_results.remove(i)
            old_result.merge(new_result)
            i -= 1
        i += 1
