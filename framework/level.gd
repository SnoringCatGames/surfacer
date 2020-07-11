extends Node2D
class_name Level

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
    Global.current_level = self

func _ready() -> void:
    var scene_tree := get_tree()
    
    # Get references to the TileMaps that define the collision boundaries of
    # this level.
    surface_tile_maps = \
            scene_tree.get_nodes_in_group(Utils.GROUP_NAME_SURFACES)
    assert(surface_tile_maps.size() > 0)
    
    # Set up the PlatformGraphs for this level.
    surface_parser = SurfaceParser.new(surface_tile_maps)
    platform_graphs = _create_platform_graphs( \
            surface_parser, \
            Global.player_params, \
            Config.DEBUG_PARAMS)
    Global.platform_graph_inspector.set_graphs(platform_graphs.values())
    
    Global.is_level_ready = true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton or \
            event is InputEventScreenTouch:
        # This ensures that pressing arrow keys won't change selections in the
        # inspector.
        Global.platform_graph_inspector.release_focus()

func _create_platform_graphs( \
        surface_parser: SurfaceParser, \
        all_player_params: Dictionary, \
        debug_params: Dictionary) -> Dictionary:
    var graphs = {}
    var player_params: PlayerParams
    var fake_player: KinematicBody2D
    var collision_params: CollisionCalcParams
    for player_name in all_player_params:
        #######################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if debug_params.has("limit_parsing") and \
                player_name != debug_params.limit_parsing.player_name:
            continue
        #######################################################################
        player_params = all_player_params[player_name]
        fake_player = add_player( \
                player_params.movement_params.player_resource_path, \
                Vector2.ZERO, \
                false, \
                true)
        fake_player.set_safe_margin(player_params.movement_params \
                .collision_margin_for_edge_calculations)
        collision_params = CollisionCalcParams.new( \
                debug_params, \
                player_params.movement_params, \
                surface_parser, \
                fake_player)
        graphs[player_name] = PlatformGraph.new( \
                player_params, \
                collision_params)
    return graphs

func add_player( \
        resource_path: String, \
        position: Vector2, \
        is_human_player: bool, \
        is_fake := false) -> Player:
    var player: Player = Utils.add_scene( \
            self, \
            resource_path, \
            !is_fake, \
            !is_fake)
    player.is_fake = is_fake
    player.position = position
    add_child(player)
    
    if !is_fake:
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
            Global.current_player_for_clicks = computer_player
        
        # Set up some annotators to help with debugging.
#        Global.canvas_layers.create_grid_indices_annotator(graph)
        Global.canvas_layers.create_player_annotator( \
                player, \
                is_human_player)
