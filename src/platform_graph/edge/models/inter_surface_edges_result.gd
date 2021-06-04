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
# This field is cleared after the PlatfromGraph is done calculating the graph
# from tile maps.
# Array<EdgeCalcResult>
var edge_calc_results := []


func _init(
        origin_surface: Surface = null,
        destination_surface: Surface = null,
        edge_type := EdgeType.UNKNOWN,
        all_jump_land_positions := []) -> void:
    self.origin_surface = origin_surface
    self.destination_surface = destination_surface
    self.edge_type = edge_type
    self.all_jump_land_positions = all_jump_land_positions


func merge(other) -> void:
    Gs.utils.concat(
            self.all_jump_land_positions,
            other.all_jump_land_positions)
    Gs.utils.concat(
            self.failed_edge_attempts,
            other.failed_edge_attempts)
    Gs.utils.concat(
            self.valid_edges,
            other.valid_edges)
    Gs.utils.concat(
            self.edge_calc_results,
            other.edge_calc_results)


static func merge_results_with_matching_destination_surfaces(
        inter_surface_edges_results: Array) -> void:
    # Dictionary<Surface, InterSurfaceEdgesResult>
    var inter_surface_edges_results_set := {}
    var i := 0
    while i < inter_surface_edges_results.size():
        var new_result: InterSurfaceEdgesResult = \
                inter_surface_edges_results[i]
        if !inter_surface_edges_results_set.has(
                new_result.destination_surface):
            inter_surface_edges_results_set[new_result.destination_surface] = \
                    new_result
        else:
            var old_result: InterSurfaceEdgesResult = \
                    inter_surface_edges_results_set[ \
                            new_result.destination_surface]
            inter_surface_edges_results.remove(i)
            old_result.merge(new_result)
            i -= 1
        i += 1


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    origin_surface = context.id_to_surface[int(json_object.o)]
    destination_surface = context.id_to_surface[int(json_object.d)]
    edge_type = json_object.t
    all_jump_land_positions = \
            _load_all_jump_land_positions_json_array(json_object.p, context)
    failed_edge_attempts = \
            _load_failed_edge_attempts_json_array(json_object.f, context)
    valid_edges = _load_valid_edges_json_array(json_object.v, context)


func _load_all_jump_land_positions_json_array(
        json_object: Array,
        context: Dictionary) -> Array:
    var result := []
    result.resize(json_object.size())
    for i in json_object.size():
        result[i] = context.id_to_jump_land_positions[int(json_object[i])]
    return result


func _load_failed_edge_attempts_json_array(
        json_object: Array,
        context: Dictionary) -> Array:
    var result := []
    result.resize(json_object.size())
    for i in json_object.size():
        var failed_edge_attempt := FailedEdgeAttempt.new()
        failed_edge_attempt.load_from_json_object(json_object[i], context)
        result[i] = failed_edge_attempt
    return result


func _load_valid_edges_json_array(
        json_object: Array,
        context: Dictionary) -> Array:
    var result := []
    result.resize(json_object.size())
    for i in json_object.size():
        result[i] = \
                Surfacer.edge_from_json_factory.create(json_object[i], context)
    return result


func to_json_object() -> Dictionary:
    return {
        o = origin_surface.get_instance_id(),
        d = destination_surface.get_instance_id(),
        t = edge_type,
        p = _get_all_jump_land_positions_json_array(),
        f = _get_failed_edge_attempts_json_array(),
        v = _get_valid_edges_json_array(),
    }


func _get_all_jump_land_positions_json_array() -> Array:
    var result := []
    result.resize(all_jump_land_positions.size())
    for i in all_jump_land_positions.size():
        result[i] = all_jump_land_positions[i].get_instance_id()
    return result


func _get_failed_edge_attempts_json_array() -> Array:
    var result := []
    result.resize(failed_edge_attempts.size())
    for i in failed_edge_attempts.size():
        result[i] = failed_edge_attempts[i].to_json_object()
    return result


func _get_valid_edges_json_array() -> Array:
    var result := []
    result.resize(valid_edges.size())
    for i in valid_edges.size():
        result[i] = valid_edges[i].to_json_object()
    return result
