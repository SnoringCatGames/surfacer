extends Node
class_name Level

const PlatformGraph = preload("res://framework/platform_graph/platform_graph.gd")
const PlatformGraphAnnotator = preload("res://framework/annotators/platform_graph_annotator.gd")
const PlayerAnnotator = preload("res://framework/annotators/player_annotator.gd")

# The TileMaps that define the collision boundaries of this level.
# Array<TileMap>
var collidables: Array
var human_player: HumanPlayer
var all_players: Array
var platform_graph: PlatformGraph
var platform_graph_annotator: PlatformGraphAnnotator
var player_annotator: PlayerAnnotator

func _enter_tree() -> void:
    var global := $"/root/Global"
    global.current_level = self

func _ready() -> void:
    var scene_tree = get_tree()
    
    # Get references to the TileMaps that define the collision boundaries of this level.
    collidables = scene_tree.get_nodes_in_group("collidables")
    assert(collidables.size() > 0)
    
    # Get a reference to the HumanPlayer.
    var human_players = scene_tree.get_nodes_in_group("human_player")
    assert(human_players.size() == 1)
    human_player = human_players[0]
    
    # Set up the PlatformGraph for this level.
    var global := $"/root/Global"
    platform_graph = PlatformGraph.new(collidables, global.player_types)
    
    # Get references to all initial players and initialize their PlatformGraphNavigators.
    all_players = Utils.get_children_by_type(self, Player)
    for player in all_players:
        player.initialize_platform_graph_navigator(platform_graph)

    # Set up some annotators that help with debugging.
    platform_graph_annotator = PlatformGraphAnnotator.new(platform_graph)
    add_child(platform_graph_annotator)
    player_annotator = PlayerAnnotator.new(human_player)
    add_child(player_annotator)

func descendant_physics_process_completed(descendant: Node) -> void:
    if descendant == human_player:
        player_annotator.check_for_update()
