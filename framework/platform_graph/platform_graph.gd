extends Reference
class_name PlatformGraph

const PlatformGraphEdges = preload("res://framework/platform_graph/platform_graph_edges.gd")
const PlatformGraphNodes = preload("res://framework/platform_graph/platform_graph_nodes.gd")

var nodes: PlatformGraphNodes
var edges := {}

func _init(tile_map: TileMap, player_types: Dictionary) -> void:
    nodes = PlatformGraphNodes.new(tile_map)
    nodes.parse_tile_map(tile_map)
    
    for player_name in player_types:
        edges[player_name] = PlatformGraphEdges.new(nodes, player_types[player_name])
