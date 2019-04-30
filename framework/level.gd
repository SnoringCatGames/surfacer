extends Node2D
class_name Level

const ClickAnnotator = preload("res://framework/annotators/click_annotator.gd")
const ComputerPlayerAnnotator = preload("res://framework/annotators/computer_player_annotator.gd")
const HumanPlayerAnnotator = preload("res://framework/annotators/human_player_annotator.gd")
const PlatformGraph = preload("res://framework/platform_graph/platform_graph.gd")
const PlatformGraphAnnotator = preload("res://framework/annotators/platform_graph_annotator.gd")

# The TileMaps that define the collision boundaries of this level.
# Array<TileMap>
var surface_tile_maps: Array
var computer_player: ComputerPlayer
var human_player: HumanPlayer
# Array<Player>
var all_players: Array
var surface_parser: SurfaceParser
# Dictionary<String, PlatformGraph>
var platform_graphs: Dictionary
var click_to_navigate: ClickToNavigate

var platform_graph_annotator: PlatformGraphAnnotator
var computer_player_annotator: ComputerPlayerAnnotator
var human_player_annotator: HumanPlayerAnnotator
var click_annotator: ClickAnnotator

func _enter_tree() -> void:
    var global := $"/root/Global"
    global.current_level = self

func _ready() -> void:
    var scene_tree = get_tree()
    
    # Get references to the TileMaps that define the collision boundaries of this level.
    surface_tile_maps = scene_tree.get_nodes_in_group("surfaces")
    assert(surface_tile_maps.size() > 0)
    
    # Set up the PlatformGraphs for this level.
    var global := $"/root/Global"
    surface_parser = SurfaceParser.new(surface_tile_maps, global.player_types)
    platform_graphs = _create_platform_graphs(surface_parser, global.player_types)
    
    # Get a reference to the HumanPlayer.
    var human_players = scene_tree.get_nodes_in_group("human_players")
    assert(human_players.size() == 1)
    human_player = human_players[0]
    
    # Get a reference to the ComputerPlayer.
    var computer_players = scene_tree.get_nodes_in_group("computer_players")
    assert(computer_players.size() == 1)# TODO: Remove, and update ComputerPlayerAnnotators
    computer_player = computer_players[0]
    
    # Get references to all initial players and initialize their PlatformGraphNavigators.
    all_players = Utils.get_children_by_type(self, Player)
    for player in all_players:
        player.initialize_platform_graph_navigator(platform_graphs[player.player_name])
    
    # Set up some annotators that help with debugging.
    # TODO: Eventually, update this to not be specific to squirrel
    platform_graph_annotator = PlatformGraphAnnotator.new(platform_graphs["squirrel"])
    add_child(platform_graph_annotator)
    computer_player_annotator = ComputerPlayerAnnotator.new(computer_player)
    add_child(computer_player_annotator)
    human_player_annotator = HumanPlayerAnnotator.new(human_player)
    add_child(human_player_annotator)
    click_annotator = ClickAnnotator.new(self)
    add_child(click_annotator)
    
    click_to_navigate = ClickToNavigate.new()
    click_to_navigate.update_level(self)
    add_child(click_to_navigate)

func _create_platform_graphs(surface_parser: SurfaceParser, \
        player_types: Dictionary) -> Dictionary:
    var graphs = {}
    for player_name in player_types:
        graphs[player_name] = PlatformGraph.new(surface_parser, player_types[player_name])
    return graphs

func descendant_physics_process_completed(descendant: Node) -> void:
    if descendant == human_player:
        human_player_annotator.check_for_update()
    if descendant == computer_player:
        computer_player_annotator.check_for_update()
