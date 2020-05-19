extends Node2D
class_name Level

var global

var platform_graph_inspector: PlatformGraphInspector

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

func _enter_tree() -> void:
    self.global = $"/root/Global"
    global.current_level = self

func _ready() -> void:
    var scene_tree := get_tree()
    var space_state := get_world_2d().direct_space_state
    
    global.space_state = space_state
    
    # Get references to the TileMaps that define the collision boundaries of this level.
    surface_tile_maps = scene_tree.get_nodes_in_group(Utils.GROUP_NAME_SURFACES)
    assert(surface_tile_maps.size() > 0)
    
    # Set up the PlatformGraphs for this level.
    surface_parser = SurfaceParser.new(surface_tile_maps)
    platform_graphs = _create_platform_graphs( \
            surface_parser, \
            space_state, \
            global.player_params, \
            Global.DEBUG_PARAMS)
    
    platform_graph_inspector = PlatformGraphInspector.new(platform_graphs.values())
    add_child(platform_graph_inspector)

static func _create_platform_graphs( \
        surface_parser: SurfaceParser, \
        space_state: Physics2DDirectSpaceState, \
        all_player_params: Dictionary, \
        debug_params: Dictionary) -> Dictionary:
    var graphs = {}
    var player_params: PlayerParams
    var collision_params: CollisionCalcParams
    for player_name in all_player_params:
        ###########################################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if debug_params.has("limit_parsing") and \
                player_name != debug_params.limit_parsing.player_name:
            continue
        ###########################################################################################
        player_params = all_player_params[player_name]
        collision_params = CollisionCalcParams.new( \
                debug_params, \
                space_state, \
                player_params.movement_params, \
                surface_parser)
        graphs[player_name] = PlatformGraph.new( \
                player_params, \
                collision_params)
    return graphs

func descendant_physics_process_completed(descendant: Node) -> void:
    if descendant is Player:
        global.canvas_layers.player_annotators[descendant].check_for_update()

func add_player( \
        resource_path: String, \
        is_human_player: bool, \
        position: Vector2) -> Player:
    var player: Player = Utils.add_scene( \
            self, \
            resource_path)
    
    player.position = position
    
    var group := \
            Utils.GROUP_NAME_HUMAN_PLAYERS if \
            is_human_player else \
            Utils.GROUP_NAME_COMPUTER_PLAYERS
    player.add_to_group(group)
    
    _record_player_reference(is_human_player)
    
    return player

func _record_player_reference(is_human_player: bool) -> void:
    var scene_tree := get_tree()
    
    var group := \
            Utils.GROUP_NAME_HUMAN_PLAYERS if \
            is_human_player else \
            Utils.GROUP_NAME_COMPUTER_PLAYERS
    var players := scene_tree.get_nodes_in_group(group)
    
    var player: Player = \
            players[0] if \
            players.size() > 0 else \
            null
    
    if player != null:
        var graph: PlatformGraph = platform_graphs[player.player_name]
        player.set_platform_graph(graph)
        
        if is_human_player:
            human_player = player
            player.init_human_player_state()
        else:
            computer_player = player
            player.init_computer_player_state()
            global.current_player_for_clicks = computer_player
        
        # Set up some annotators to help with debugging.
        global.canvas_layers.create_graph_annotator(graph)
        global.canvas_layers.create_player_annotator( \
                player, \
                is_human_player)
        
