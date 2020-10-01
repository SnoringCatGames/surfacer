extends Node2D
class_name Level

const TILE_MAP_COLLISION_LAYER := 7

const MUSIC_STREAM := preload("res://assets/music/on_a_quest.ogg")

# The TileMaps that define the collision boundaries of this level.
# Array<TileMap>
var surface_tile_maps: Array
# Array<Player>
var all_players: Array
# Dictionary<String, Player>
var fake_players := {}
var surface_parser: SurfaceParser
# Dictionary<String, PlatformGraph>
var platform_graphs: Dictionary
var music_player: AudioStreamPlayer

func _enter_tree() -> void:
    Global.current_level = self
    
    music_player = AudioStreamPlayer.new()
    add_child(music_player)

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
    
    _parse_squirrel_destinations()
    
    _start_music()
    
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
    var fake_player: Player
    var collision_params: CollisionCalcParams
    var graph: PlatformGraph
    for player_name in all_player_params:
        #######################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if debug_params.has("limit_parsing") and \
                debug_params.limit_parsing.has("player_name") and \
                player_name != debug_params.limit_parsing.player_name:
            continue
        #######################################################################
        player_params = all_player_params[player_name]
        fake_player = create_fake_player_for_graph_calculation(player_params)
        collision_params = CollisionCalcParams.new( \
                debug_params, \
                player_params.movement_params, \
                surface_parser, \
                fake_player)
        graph = PlatformGraph.new( \
                player_params, \
                collision_params)
        fake_player.set_platform_graph(graph)
        graphs[player_name] = graph
    return graphs

func create_fake_player_for_graph_calculation( \
        player_params: PlayerParams) -> Player:
    var fake_player := add_player( \
            player_params.movement_params.player_resource_path, \
            Vector2.ZERO, \
            false, \
            true)
    fake_player.collision_layer = 0
    fake_player.collision_mask = TILE_MAP_COLLISION_LAYER
    fake_player.set_safe_margin(player_params.movement_params \
            .collision_margin_for_edge_calculations)
    fake_players[fake_player.player_name] = fake_player
    return fake_player

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
    
    if is_fake:
        player.collision_layer = 0
    else:
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
        if graph != null:
            player.set_platform_graph(graph)
        
        if is_human_player:
            player.init_human_player_state()
            Global.current_player_for_clicks = player
        else:
            player.init_computer_player_state()
        
        # Set up some annotators to help with debugging.
        Global.canvas_layers.create_player_annotator( \
                player, \
                is_human_player)

func set_level_visibility(is_visible: bool) -> void:
    # TODO: Also show/hide background. Parallax doesn't extend from CanvasItem
    #       or have the `visible` field though.
#    var backgrounds := Utils.get_children_by_type( \
#            self, \
#            ParallaxBackground)
    var foregrounds := Utils.get_children_by_type( \
            self, \
            TileMap)
    for node in foregrounds:
        node.visible = is_visible

# Array<PositionAlongSurface>
var squirrel_destinations := []

# FIXME: Decouple this squirrel-specific logic from the rest of the framework.
func _parse_squirrel_destinations() -> void:
    squirrel_destinations.clear()
    var configured_destinations := get_tree().get_nodes_in_group( \
            Utils.GROUP_NAME_SQUIRREL_DESTINATIONS)
    if !configured_destinations.empty():
        assert(configured_destinations.size() == 1)
        var squirrel_player: SquirrelPlayer = \
                platform_graphs["squirrel"].collision_params.player
        for configured_point in configured_destinations[0].get_children():
            assert(configured_point is Position2D)
            var destination := \
                    SurfaceParser.find_closest_position_on_a_surface( \
                            configured_point.position, \
                            squirrel_player)
            squirrel_destinations.push_back(destination)
    else:
        for i in range(6):
            squirrel_destinations.push_back( \
                    _create_random_squirrel_spawn_position())

func _create_random_squirrel_spawn_position() -> PositionAlongSurface:
    var bounds := surface_parser.combined_tile_map_rect.grow( \
            -SquirrelPlayer.SQUIRREL_SPAWN_LEVEL_OUTER_MARGIN)
    var x := randf() * bounds.size.x + bounds.position.x
    var y := randf() * bounds.size.y + bounds.position.y
    var point := Vector2(x, y)
    return SurfaceParser.find_closest_position_on_a_surface( \
            point, \
            fake_players["squirrel"])

func _start_music() -> void:
    music_player.stream = MUSIC_STREAM
    music_player.play()
