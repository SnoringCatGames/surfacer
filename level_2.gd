extends Node

const PlatformGraph = preload("platform_graph.gd")

func _ready():
    var graph = PlatformGraph.new()
    graph.parse_tile_map($WallsAndFloors)
