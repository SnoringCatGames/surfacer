# Information for how to move from surface to surface to get from the given
# origin to the given destination.
class_name PlatformGraphPath
extends Reference

# Array<Edge>
var edges: Array

var origin := Vector2.INF
var destination := Vector2.INF

var duration: float

func _init(edges: Array) -> void:
    self.edges = edges
    self.origin = edges.front().get_start()
    self.destination = edges.back().get_end()
    self.duration = _calculate_duration()

func _calculate_duration() -> float:
    var duration := 0.0
    for edge in edges:
        duration += edge.duration
    return duration

func push_front(edge: Edge) -> void:
    assert(Gs.geometry.are_points_equal_with_epsilon(edge.get_end(), origin))
    self.edges.push_front(edge)
    self.origin = edge.get_start()

func push_back(edge: Edge) -> void:
    assert(Gs.geometry.are_points_equal_with_epsilon(edge.start, destination))
    self.edges.push_back(edge)
    self.destination = edge.get_end()

func predict_animation_state(
        result: PlayerAnimationState,
        path_time: float) -> bool:
    var is_before_path_end_time := path_time <= duration
    if !is_before_path_end_time:
        var last_edge: Edge = edges.back()
        last_edge.get_animation_state_at_time(result, last_edge.duration)
        return false
    
    var edge_start_time := 0.0
    var prediction_edge: Edge
    var prediction_edge_start_time := INF
    for edge in edges:
        if edge_start_time + edge.duration >= path_time:
            prediction_edge = edge
            prediction_edge_start_time = edge_start_time
            break
        edge_start_time += edge.duration
    if prediction_edge == null:
        prediction_edge = edges.back()
        prediction_edge_start_time = edge_start_time
    
    var prediction_edge_time := path_time - prediction_edge_start_time
    prediction_edge.get_animation_state_at_time(result, prediction_edge_time)
    
    return true

func to_string_with_newlines(indent_level := 0) -> String:
    var indent_level_str := ""
    for i in indent_level:
        indent_level_str += "\t"
    var edges_str := ""
    for edge in edges:
        edges_str += "\n\t\t%s%s, " % [
                indent_level_str,
                edge.to_string_with_newlines(indent_level + 2),
            ]
    var format_string_template := (
            "PlatformGraphPath{ " +
            "\n\t%sorigin: %s," +
            "\n\t%sdestination: %s," +
            "\n\t%sedges: [" +
            "%s" +
            "\n\t%s]," +
            "\n%s}")
    var format_string_arguments := [
            indent_level_str,
            String(origin),
            indent_level_str,
            String(destination),
            indent_level_str,
            edges_str,
            indent_level_str,
            indent_level_str,
        ]
    return format_string_template % format_string_arguments
