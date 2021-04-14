# Information for how to move from surface to surface to get from the given origin to the given
# destination.
class_name PlatformGraphPath
extends Reference

# Array<Edge>
var edges: Array

var origin := Vector2.INF
var destination := Vector2.INF

func _init(edges: Array) -> void:
    self.edges = edges
    self.origin = edges.front().get_start()
    self.destination = edges.back().get_end()

func push_front(edge: Edge) -> void:
    assert(Gs.geometry.are_points_equal_with_epsilon(edge.get_end(), origin))
    self.edges.push_front(edge)
    self.origin = edge.get_start()

func push_back(edge: Edge) -> void:
    assert(Gs.geometry.are_points_equal_with_epsilon(edge.start, destination))
    self.edges.push_back(edge)
    self.destination = edge.get_end()

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
    var format_string_template := "PlatformGraphPath{ " + \
            "\n\t%sorigin: %s," + \
            "\n\t%sdestination: %s," + \
            "\n\t%sedges: [" + \
            "%s" + \
            "\n\t%s]," + \
            "\n%s}"
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
