extends Node2D
class_name Level

const ClickAnnotator = preload("res://framework/annotators/click_annotator.gd")
const ComputerPlayerAnnotator = preload("res://framework/annotators/computer_player_annotator.gd")
const HumanPlayerAnnotator = preload("res://framework/annotators/human_player_annotator.gd")
const PlatformGraph = preload("res://framework/platform_graph/platform_graph.gd")
const PlatformGraphAnnotator = preload("res://framework/annotators/platform_graph_annotator.gd")

# The TileMaps that define the collision boundaries of this level.
# Array<TileMap>
var surfaces: Array
var computer_player: ComputerPlayer
var human_player: HumanPlayer
var all_players: Array
var platform_graph: PlatformGraph
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
    surfaces = scene_tree.get_nodes_in_group("surfaces")
    assert(surfaces.size() > 0)
    
    # Get a reference to the ComputerPlayer.
    var computer_players = scene_tree.get_nodes_in_group("computer_players")
    assert(computer_players.size() == 1)
    computer_player = computer_players[0]
    
    # Get a reference to the HumanPlayer.
    var human_players = scene_tree.get_nodes_in_group("human_players")
    assert(human_players.size() == 1)
    human_player = human_players[0]
    
    # Set up the PlatformGraph for this level.
    var global := $"/root/Global"
    platform_graph = PlatformGraph.new(surfaces, global.player_types)
    
    # Get references to all initial players and initialize their PlatformGraphNavigators.
    all_players = Utils.get_children_by_type(self, Player)
    for player in all_players:
        player.initialize_platform_graph_navigator(platform_graph)
    
    # Set up some annotators that help with debugging.
    platform_graph_annotator = PlatformGraphAnnotator.new(platform_graph)
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

func descendant_physics_process_completed(descendant: Node) -> void:
    if descendant == human_player:
        human_player_annotator.check_for_update()
    if descendant == computer_player:
        computer_player_annotator.check_for_update()
