class_name SurfacerLevel
extends ScaffolderLevel

const PLATFORM_GRAPHS_DIRECTORY_NAME := "platform_graphs"

const _UTILITY_PANEL_RESOURCE_PATH := \
        "res://addons/surfacer/src/gui/panels/InspectorPanel.tscn"
const _PAUSE_BUTTON_RESOURCE_PATH := \
        "res://addons/surfacer/src/gui/PauseButton.tscn"

# The TileMaps that define the collision boundaries of this level.
# Array<SurfacesTileMap>
var surface_tile_maps: Array
# Array<Player>
var all_players: Array
# Dictionary<String, Player>
var fake_players := {}
var surface_parser: SurfaceParser
# Dictionary<String, PlatformGraph>
var platform_graphs: Dictionary
var inspector_panel: InspectorPanel
var pause_button: PauseButton

func start() -> void:
    .start()
    
    if Surfacer.is_inspector_enabled:
        inspector_panel = Gs.utils.add_scene( \
                Gs.canvas_layers.layers.hud, \
                _UTILITY_PANEL_RESOURCE_PATH)
        Surfacer.inspector_panel = inspector_panel
    else:
        pause_button = Gs.utils.add_scene( \
                Gs.canvas_layers.layers.hud, \
                _PAUSE_BUTTON_RESOURCE_PATH)
    
    _create_fake_players_for_collision_calculations()
    _record_tile_maps()
    _instantiate_platform_graphs()

func _create_fake_players_for_collision_calculations() -> void:
    for player_name in Surfacer.player_params:
        var movement_params: MovementParams = \
                Surfacer.player_params[player_name].movement_params
        var fake_player := add_player( \
                movement_params.player_resource_path, \
                Vector2.ZERO, \
                false, \
                true)
        fake_player.set_safe_margin( \
                movement_params.collision_margin_for_edge_calculations)
        fake_players[fake_player.player_name] = fake_player

func _instantiate_platform_graphs() -> void:
    var platform_graphs_path := \
            "res://%s/level_%s.json" % [PLATFORM_GRAPHS_DIRECTORY_NAME, _id]
    if File.new().file_exists(platform_graphs_path):
        _load_platform_graphs()
    else:
        # Set up the PlatformGraphs for this level.
        surface_parser = SurfaceParser.new()
        surface_parser.calculate(surface_tile_maps)
        platform_graphs = _calculate_platform_graphs()
    
    if Surfacer.is_inspector_enabled:
        Surfacer.platform_graph_inspector.set_graphs(platform_graphs.values())
    
    call_deferred("_initialize_annotators")

# Get references to the TileMaps that define the collision boundaries of this
# level.
func _record_tile_maps() -> void:
    surface_tile_maps = \
            get_tree().get_nodes_in_group(Surfacer.group_name_surfaces)
    
    # Validate the TileMaps.
    if Gs.debug or Gs.playtest:
        assert(surface_tile_maps.size() > 0)
        var tile_map_ids := {}
        for tile_map in surface_tile_maps:
            assert(tile_map is SurfacesTileMap)
            assert(tile_map.id != "" or surface_tile_maps.size() == 1)
            assert(!tile_map_ids.has(tile_map.id))
            tile_map_ids[tile_map.id] = true

func _initialize_annotators() -> void:
    set_tile_map_visibility(false)
    Surfacer.annotators.on_level_ready()

func _destroy() -> void:
    for group in [ \
            Surfacer.group_name_human_players, \
            Surfacer.group_name_computer_players]:
        for player in get_tree().get_nodes_in_group(group):
            player._destroy()
    
    if is_instance_valid(inspector_panel):
        inspector_panel.queue_free()
    if is_instance_valid(pause_button):
        pause_button.queue_free()
    Surfacer.annotators.on_level_destroyed()
    Surfacer.current_player_for_clicks = null
    
    ._destroy()

func quit(immediately := true) -> void:
    .quit(immediately)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton or \
            event is InputEventScreenTouch:
        # This ensures that pressing arrow keys won't change selections in the
        # inspector.
        Gs.utils.release_focus()

func _calculate_platform_graphs() -> Dictionary:
    var graphs = {}
    var graph: PlatformGraph
    for player_name in Surfacer.player_params:
        #######################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if Surfacer.debug_params.has("limit_parsing") and \
                Surfacer.debug_params.limit_parsing.has("player_name") and \
                player_name != Surfacer.debug_params.limit_parsing.player_name:
            continue
        #######################################################################
        graph = PlatformGraph.new()
        graph.calculate(player_name)
        graphs[player_name] = graph
    return graphs

func add_player( \
        resource_path: String, \
        position: Vector2, \
        is_human_player: bool, \
        is_fake := false) -> Player:
    var player: Player = Gs.utils.add_scene( \
            self, \
            resource_path, \
            !is_fake, \
            !is_fake)
    player.is_fake = is_fake
    player.position = position
    player.name = "fake_" + player.name
    add_child(player)
    
    if !is_fake:
        var group: String = \
                Surfacer.group_name_human_players if \
                is_human_player else \
                Surfacer.group_name_computer_players
        player.add_to_group(group)
        
        var graph: PlatformGraph = platform_graphs[player.player_name]
        if graph != null:
            player.set_platform_graph(graph)
        
        if is_human_player:
            player.init_human_player_state()
            Surfacer.current_player_for_clicks = player
        else:
            player.init_computer_player_state()
        
        # Set up some annotators to help with debugging.
        player.set_is_sprite_visible(false)
        Surfacer.annotators.create_player_annotator( \
                player, \
                is_human_player)
    
    return player

func set_tile_map_visibility(is_visible: bool) -> void:
    # TODO: Also show/hide background. Parallax doesn't extend from CanvasItem
    #       or have the `visible` field though.
#    var backgrounds := Gs.utils.get_children_by_type( \
#            self, \
#            ParallaxBackground)
    var foregrounds := Gs.utils.get_children_by_type( \
            self, \
            TileMap)
    for node in foregrounds:
        node.visible = is_visible

func _load_platform_graphs() -> void:
    var platform_graphs_path := \
            "res://%s/level_%s.json" % [PLATFORM_GRAPHS_DIRECTORY_NAME, _id]
    
    var file := File.new()
    var status := file.open(platform_graphs_path, File.READ)
    if status != OK:
        push_error("Unable to open file: " + platform_graphs_path)
        return
    
    var serialized_string := file.get_as_text()
    var parse_result := JSON.parse(serialized_string)
    if parse_result.error != OK:
        push_error("Unable to parse JSON: %s; %s:%s:%s" % [ \
            platform_graphs_path, \
            parse_result.error, \
            parse_result.error_line, \
            parse_result.error_string, \
        ])
        return
    var json_object: Dictionary = parse_result.result
    
    var context := {
        id_to_tile_map = {},
        id_to_surface = {},
        id_to_position_along_surface = {},
        id_to_jump_land_positions = {},
        id_to_edge_attempt = {},
    }
    for tile_map in surface_tile_maps:
        context.id_to_tile_map[tile_map.id] = tile_map
    
    if Gs.debug or Gs.playtest:
        _validate_tile_maps(json_object)
        _validate_players(json_object)
        _validate_surfaces(json_object)
        _validate_platform_graphs(json_object)
    
    surface_parser = SurfaceParser.new()
    surface_parser.load_from_json_object( \
            json_object.surface_parser, \
            context)
    
    for graph_json_object in json_object.platform_graphs:
        var graph := PlatformGraph.new()
        graph.load_from_json_object( \
                graph_json_object, \
                context)
        platform_graphs[graph.player_params.name] = graph

func _validate_tile_maps(json_object: Dictionary) -> void:
    var expected_id_set := {}
    for tile_map in surface_tile_maps:
        expected_id_set[tile_map.id] = true
    
    for id in json_object.surfaces_tile_map_ids:
        assert(expected_id_set.has(id))
        expected_id_set.erase(id)
    assert(expected_id_set.empty())

func _validate_players(json_object: Dictionary) -> void:
    var expected_name_set := {}
    for player_name in Surfacer.player_params:
        expected_name_set[player_name] = true
    
    for name in json_object.player_names:
        assert(expected_name_set.has(name))
        expected_name_set.erase(name)
    assert(expected_name_set.empty())

func _validate_surfaces(json_object: Dictionary) -> void:
    # FIXME: ------------------------------------
    pass

func _validate_platform_graphs(json_object: Dictionary) -> void:
    # FIXME: ------------------------------------
    pass

# FIXME: ------------------------------- Call this
func save_platform_graphs() -> void:
    assert(Gs.utils.get_is_pc_device())
    
    var json_object := to_json_object()
    var serialized_string := JSON.print(json_object)
    
    var directory_path := \
            ProjectSettings.globalize_path("res://") + \
            PLATFORM_GRAPHS_DIRECTORY_NAME
    
    if !Gs.utils.ensure_directory_exists(directory_path):
        return
    
    var file_name := "level_%s.json" % _id
    var path := directory_path + "/" + file_name
    
    var file := File.new()
    var status := file.open(path, File.WRITE)
    if status != OK:
        push_error("Unable to open file: " + path)
    file.store_string(serialized_string)
    file.close()

func to_json_object() -> Dictionary:
    return {
        level_id = _id,
        surfaces_tile_map_ids = _get_surfaces_tile_map_ids(),
        player_names = _get_player_names(),
        surface_parser = surface_parser.to_json_object(),
        platform_graphs = _serialize_platform_graphs(),
    }

func _get_surfaces_tile_map_ids() -> Array:
    var result := []
    result.resize(surface_tile_maps.size())
    for i in surface_tile_maps.size():
        result[i] = surface_tile_maps[i].id
    return result

func _get_player_names() -> Array:
    var result := []
    result.resize(all_players.size())
    for i in all_players.size():
        result[i] = all_players[i].player_name
    return result

func _serialize_platform_graphs() -> Array:
    var result := []
    result.resize(platform_graphs.size())
    for i in platform_graphs.size():
        result[i] = platform_graphs[i].to_json_object()
    return result
