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
var computer_player: Player
var human_player: Player
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
    var scene_tree := get_tree()
    
    # Get references to the TileMaps that define the collision boundaries of this level.
    surface_tile_maps = scene_tree.get_nodes_in_group(Utils.GROUP_NAME_SURFACES)
    assert(surface_tile_maps.size() > 0)
    
    # Set up the PlatformGraphs for this level.
    var space_state := get_world_2d().direct_space_state
    var global := $"/root/Global"
    surface_parser = SurfaceParser.new(surface_tile_maps, global.player_types)
    platform_graphs = _create_platform_graphs(surface_parser, space_state, global.player_types)
    
    click_to_navigate = ClickToNavigate.new()
    click_to_navigate.update_level(self)
    add_child(click_to_navigate)
    
    # Get references to all initial players and initialize their PlatformGraphNavigators.
    all_players = Utils.get_children_by_type(self, Player)
    for player in all_players:
        player.initialize_platform_graph_navigator(platform_graphs[player.player_name])
    
    _record_player_reference(true)
    _record_player_reference(false)
    
    # Set up some annotators that help with debugging.
    platform_graph_annotator = PlatformGraphAnnotator.new(platform_graphs["test"])
    add_child(platform_graph_annotator)
    click_annotator = ClickAnnotator.new(self)
    add_child(click_annotator)

static func _create_platform_graphs(surface_parser: SurfaceParser, \
        space_state: Physics2DDirectSpaceState, player_types: Dictionary) -> Dictionary:
    var graphs = {}
    for player_name in player_types:
        graphs[player_name] = \
                PlatformGraph.new(surface_parser, space_state, player_types[player_name])
    return graphs

func descendant_physics_process_completed(descendant: Node) -> void:
    if descendant == human_player:
        human_player_annotator.check_for_update()
    if descendant == computer_player:
        computer_player_annotator.check_for_update()

func add_player(resource_path: String, is_human_player: bool, position: Vector2) -> Player:
    var player: Player = Utils.add_scene(self, resource_path)
    
    player.position = position
    
    var group := Utils.GROUP_NAME_HUMAN_PLAYERS if is_human_player else \
            Utils.GROUP_NAME_COMPUTER_PLAYERS
    player.add_to_group(group)
    
    _record_player_reference(is_human_player)
    
    return player

func _record_player_reference(is_human_player: bool) -> void:
    var scene_tree := get_tree()
    
    var group := Utils.GROUP_NAME_HUMAN_PLAYERS if is_human_player else \
            Utils.GROUP_NAME_COMPUTER_PLAYERS
    var players := scene_tree.get_nodes_in_group(group)
    
    var player: Player = players[0] if players.size() > 0 else null
    
    # FIXME: LEFT OFF HERE: DEBUGGING:
    # - Something's up with how I instance TestPlayer.
    # - It somehow doesn't ever instantiate the Player class, but it does instantiate KinematicBody2D??
    # - NEXT STEP: Walk through diff of changes...
    if player != null:
        if is_human_player:
            human_player = player
            
            human_player.set_is_human_controlled(true)
            
            # Set up an annotator to help with debugging.
            human_player_annotator = HumanPlayerAnnotator.new(human_player)
            add_child(human_player_annotator)
            
            human_player_annotator.initialize_platform_graph_navigator()
        else:
            computer_player = player
            
            computer_player.set_is_human_controlled(false)
            
            # Set up an annotator to help with debugging.
            computer_player_annotator = ComputerPlayerAnnotator.new(computer_player)
            add_child(computer_player_annotator)
            
            computer_player_annotator.initialize_platform_graph_navigator()
            
            click_to_navigate.set_computer_player(computer_player)
            click_annotator.set_computer_player(computer_player)
