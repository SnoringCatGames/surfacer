extends Node2D
class_name Level

const ClickAnnotator := preload("res://framework/annotators/click_annotator.gd")
const PlayerAnnotator := preload("res://framework/annotators/player_annotator.gd")
const PlatformGraph := preload("res://framework/platform_graph/platform_graph.gd")
const PlatformGraphAnnotator := preload("res://framework/annotators/platform_graph_annotator.gd")
const RulerAnnotator := preload("res://framework/annotators/ruler_annotator.gd")

var global: Global

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
var ruler_annotator: RulerAnnotator
# Dictonary<Player, PlayerAnnotator>
var player_annotators := {}
var click_annotator: ClickAnnotator

func _enter_tree() -> void:
    self.global = $"/root/Global"
    global.current_level = self
    
    _add_overlays()

func _add_overlays() -> void:
    var ruler_layer := CanvasLayer.new()
    ruler_layer.layer = 100
    global.add_overlay_to_current_scene(ruler_layer)
    
    ruler_annotator = RulerAnnotator.new(global)
    ruler_layer.add_child(ruler_annotator)
    
    var hud_layer := CanvasLayer.new()
    hud_layer.layer = 200
    global.add_overlay_to_current_scene(hud_layer)
    # TODO: Add HUD content.
    
    var menu_layer := CanvasLayer.new()
    menu_layer.layer = 300
    global.add_overlay_to_current_scene(menu_layer)
    # TODO: Add start and pause menus.
    
    var debug_panel = Utils.add_scene(hud_layer, Global.DEBUG_PANEL_RESOURCE_PATH)
    global.debug_panel = debug_panel

func _ready() -> void:
    var scene_tree := get_tree()
    
    # Get references to the TileMaps that define the collision boundaries of this level.
    surface_tile_maps = scene_tree.get_nodes_in_group(Utils.GROUP_NAME_SURFACES)
    assert(surface_tile_maps.size() > 0)
    
    # Set up the PlatformGraphs for this level.
    var space_state := get_world_2d().direct_space_state
    surface_parser = SurfaceParser.new(surface_tile_maps, global.player_types)
    platform_graphs = _create_platform_graphs( \
            surface_parser, space_state, global.player_types, global.DEBUG_STATE)
    
    click_to_navigate = ClickToNavigate.new()
    click_to_navigate.update_level(self)
    add_child(click_to_navigate)
    
    # Set up some annotators that help with debugging.
    click_annotator = ClickAnnotator.new(self)
    add_child(click_annotator)

static func _create_platform_graphs(surface_parser: SurfaceParser, \
        space_state: Physics2DDirectSpaceState, player_types: Dictionary, \
        debug_state: Dictionary) -> Dictionary:
    var graphs = {}
    for player_name in player_types:
        graphs[player_name] = PlatformGraph.new( \
                surface_parser, space_state, player_types[player_name], debug_state)
    return graphs

func descendant_physics_process_completed(descendant: Node) -> void:
    if descendant is Player:
        player_annotators[descendant].check_for_update()

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
    
    if player != null:
        var graph: PlatformGraph = platform_graphs[player.player_name]
        player.set_platform_graph(graph)
        
        if is_human_player:
            human_player = player
            player.init_human_player_state()
        else:
            computer_player = player
            player.init_computer_player_state()
            click_to_navigate.set_player(computer_player)
            click_annotator.set_player(computer_player)
        
        # Set up an annotator to help with debugging.
        platform_graph_annotator = PlatformGraphAnnotator.new(graph)
        add_child(platform_graph_annotator)
        var player_annotator := PlayerAnnotator.new(player, !is_human_player)
        add_child(player_annotator)
        player_annotators[player] = player_annotator
