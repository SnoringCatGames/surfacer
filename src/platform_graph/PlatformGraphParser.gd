class_name PlatformGraphParser
extends Node

signal calculation_started
signal load_started
signal calculation_progress(
        player_index,
        player_count,
        origin_surface_index,
        surface_count)
signal parse_finished

const PLATFORM_GRAPHS_DIRECTORY_NAME := "platform_graphs"

var level_id: String
# The TileMaps that define the collision boundaries of this level.
# Array<SurfacesTileMap>
var surface_tile_maps: Array
# Dictionary<String, Player>
var fake_players := {}
var surface_parser: SurfaceParser
# Dictionary<String, PlatformGraph>
var platform_graphs: Dictionary
var is_loaded_from_file := false
var is_parse_finished := false

func _enter_tree() -> void:
    Surfacer.graph_parser = self

func _exit_tree() -> void:
    Surfacer.graph_parser = null

func parse(
        level_id: String,
        force_calculation_from_tile_maps := false) -> void:
    self.level_id = level_id
    _record_tile_maps()
    _create_fake_players_for_collision_calculations()
    force_calculation_from_tile_maps = \
            force_calculation_from_tile_maps or \
            Surfacer.ignores_platform_graph_save_files
    _instantiate_platform_graphs(force_calculation_from_tile_maps)

# Get references to the TileMaps that define the collision boundaries of this
# level.
func _record_tile_maps() -> void:
    surface_tile_maps = \
            Gs.utils.get_all_nodes_in_group(Surfacer.group_name_surfaces)
    
    # Validate the TileMaps.
    if Gs.debug or Gs.playtest:
        assert(surface_tile_maps.size() > 0)
        var tile_map_ids := {}
        for tile_map in surface_tile_maps:
            assert(tile_map is SurfacesTileMap)
            assert(tile_map.id != "" or surface_tile_maps.size() == 1)
            assert(!tile_map_ids.has(tile_map.id))
            tile_map_ids[tile_map.id] = true

func _create_fake_players_for_collision_calculations() -> void:
    for player_name in _get_player_names():
        var movement_params: MovementParams = \
                Surfacer.player_params[player_name].movement_params
        var fake_player: Player = Gs.utils.add_scene(
                self,
                movement_params.player_resource_path,
                false,
                false)
        fake_player.is_fake = true
        fake_player.name = "fake_" + fake_player.name
        fake_player.set_safe_margin(
                movement_params.collision_margin_for_edge_calculations)
        add_child(fake_player)
        fake_players[fake_player.player_name] = fake_player

func _instantiate_platform_graphs(
        force_calculation_from_tile_maps := false) -> void:
    is_loaded_from_file = \
            !force_calculation_from_tile_maps and \
            File.new().file_exists(_get_resource_path())
    if is_loaded_from_file:
        emit_signal("load_started")
        Gs.time.set_timeout(
                funcref(self, "_load_platform_graphs"),
                0.3)
    else:
        # Set up the PlatformGraphs for this level.
        surface_parser = SurfaceParser.new()
        surface_parser.calculate(surface_tile_maps)
        platform_graphs = {}
        assert(!Surfacer.player_params.empty())
        emit_signal("calculation_started")
        _defer_calculate_next_platform_graph(-1)

func _on_graphs_parsed() -> void:
    if Surfacer.is_inspector_enabled:
        Surfacer.graph_inspector.set_graphs(platform_graphs.values())
    
    for platform_graph in platform_graphs.values():
        if platform_graph.is_connected(
                    "calculation_progress",
                    self,
                    "_on_graph_calculation_progress"):
            platform_graph.disconnect(
                    "calculation_progress",
                    self,
                    "_on_graph_calculation_progress")
        if platform_graph.is_connected(
                    "calculation_finished",
                    self,
                    "_on_graph_calculation_finished"):
            platform_graph.disconnect(
                    "calculation_finished",
                    self,
                    "_on_graph_calculation_finished")
    
    is_parse_finished = true
    
    emit_signal("parse_finished")

func _calculate_next_platform_graph(player_index: int) -> void:
    var player_names: Array = _get_player_names()
    var player_name: String = player_names[player_index]
    var is_last_player := player_index == player_names.size() - 1
    
    #######################################################################
    # Allow for debug mode to limit the scope of what's calculated.
    var should_skip_player: bool = \
            Surfacer.debug_params.has("limit_parsing") and \
            Surfacer.debug_params.limit_parsing.has("player_name") and \
            player_name != Surfacer.debug_params.limit_parsing.player_name
    #######################################################################
    
    if !should_skip_player:
        var graph := PlatformGraph.new()
        graph.connect(
                "calculation_progress",
                self,
                "_on_graph_calculation_progress",
                [graph, player_index, player_name])
        graph.connect(
                "calculation_finished",
                self,
                "_on_graph_calculation_finished",
                [player_index, is_last_player])
        graph.calculate(player_name)
        platform_graphs[player_name] = graph
    else:
        if !is_last_player:
            _calculate_next_platform_graph(player_index + 1)
        else:
            _on_graphs_parsed()

func _on_graph_calculation_progress(
        origin_surface_index,
        surface_count,
        graph: PlatformGraph,
        player_index: int,
        player_name: String) -> void:
    emit_signal(
            "calculation_progress",
            player_index,
            _get_player_names().size(),
            origin_surface_index,
            surface_count)

func _on_graph_calculation_finished(
        player_index: int,
        was_last_player: bool) -> void:
    if !was_last_player:
        _defer_calculate_next_platform_graph(player_index)
    else:
        _on_graphs_parsed()

func _defer_calculate_next_platform_graph(last_player_index: int) -> void:
    Gs.time.set_timeout(
            funcref(self, "_calculate_next_platform_graph"),
            0.01,
            [last_player_index + 1])

func _load_platform_graphs() -> void:
    var platform_graphs_path := _get_resource_path()
    
    var file := File.new()
    var status := file.open(platform_graphs_path, File.READ)
    if status != OK:
        Gs.logger.error("Unable to open file: " + platform_graphs_path)
        return
    
    var serialized_string := file.get_as_text()
    var parse_result := JSON.parse(serialized_string)
    if parse_result.error != OK:
        Gs.logger.error("Unable to parse JSON: %s; %s:%s:%s" % [
            platform_graphs_path,
            parse_result.error,
            parse_result.error_line,
            parse_result.error_string,
        ])
        return
    var json_object: Dictionary = parse_result.result
    
    var context := {
        id_to_tile_map = {},
        id_to_surface = {},
        id_to_position_along_surface = {},
        id_to_jump_land_positions = {},
    }
    for tile_map in surface_tile_maps:
        context.id_to_tile_map[tile_map.id] = tile_map
    
    surface_parser = SurfaceParser.new()
    surface_parser.load_from_json_object(
            json_object.surface_parser,
            context)
    
    if Gs.debug or Gs.playtest:
        _validate_tile_maps(json_object)
        _validate_players(json_object)
        _validate_surfaces(surface_parser)
        _validate_platform_graphs(json_object)
    
    for graph_json_object in json_object.platform_graphs:
        var graph := PlatformGraph.new()
        graph.load_from_json_object(
                graph_json_object,
                context)
        platform_graphs[graph.player_params.name] = graph
    
    _on_graphs_parsed()

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
    for player_name in _get_player_names():
        expected_name_set[player_name] = true
    
    for name in json_object.player_names:
        assert(expected_name_set.has(name))
        expected_name_set.erase(name)
    assert(expected_name_set.empty())

func _validate_surfaces(surface_parser: SurfaceParser) -> void:
    var expected_id_set := {}
    for tile_map in surface_tile_maps:
        expected_id_set[tile_map.id] = true
    
    for tile_map in surface_parser._tile_map_index_to_surface_maps:
        assert(expected_id_set.has(tile_map.id))
        expected_id_set.erase(tile_map.id)
    assert(expected_id_set.empty())
    
    if Surfacer.are_loaded_surfaces_deeply_validated:
        var expected_surface_parser = SurfaceParser.new()
        expected_surface_parser.calculate(surface_tile_maps)
        
        assert(surface_parser.max_tile_map_cell_size == \
                expected_surface_parser.max_tile_map_cell_size)
        assert(surface_parser.combined_tile_map_rect == \
                expected_surface_parser.combined_tile_map_rect)
        
        assert(surface_parser.floors.size() == \
                expected_surface_parser.floors.size())
        assert(surface_parser.ceilings.size() == \
                expected_surface_parser.ceilings.size())
        assert(surface_parser.left_walls.size() == \
                expected_surface_parser.left_walls.size())
        assert(surface_parser.right_walls.size() == \
                expected_surface_parser.right_walls.size())
        
        for i in surface_parser.floors.size():
            assert(surface_parser.floors[i].probably_equal(
                    expected_surface_parser.floors[i]))
        
        for i in surface_parser.ceilings.size():
            assert(surface_parser.ceilings[i].probably_equal(
                    expected_surface_parser.ceilings[i]))
        
        for i in surface_parser.left_walls.size():
            assert(surface_parser.left_walls[i].probably_equal(
                    expected_surface_parser.left_walls[i]))
        
        for i in surface_parser.right_walls.size():
            assert(surface_parser.right_walls[i].probably_equal(
                    expected_surface_parser.right_walls[i]))

func _validate_platform_graphs(json_object: Dictionary) -> void:
    var expected_name_set := {}
    for player_name in _get_player_names():
        expected_name_set[player_name] = true
    
    for graph_json_object in json_object.platform_graphs:
        assert(expected_name_set.has(graph_json_object.player_name))
        expected_name_set.erase(graph_json_object.player_name)
    
    assert(expected_name_set.empty())

func save_platform_graphs() -> void:
    assert(Gs.utils.get_is_pc_device())
    
    var json_object := to_json_object()
    var serialized_string := JSON.print(json_object)
    
    if !Gs.utils.ensure_directory_exists(get_directory_path()):
        return
    
    var file_name: String = "level_%s.json" % level_id
    var path := get_directory_path() + "/" + file_name
    
    var file := File.new()
    var status := file.open(path, File.WRITE)
    if status != OK:
        Gs.logger.error("Unable to open file: " + path)
    file.store_string(serialized_string)
    file.close()

func to_json_object() -> Dictionary:
    return {
        level_id = level_id,
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
    return Gs.level_config.get_level_config(level_id).player_names

func _serialize_platform_graphs() -> Array:
    var result := []
    for player_name in platform_graphs:
        result.push_back(platform_graphs[player_name].to_json_object())
    return result

func _get_resource_path() -> String:
    return "res://%s/level_%s.json" % [
        PLATFORM_GRAPHS_DIRECTORY_NAME,
        level_id,
    ]

static func get_directory_path() -> String:
    return ProjectSettings.globalize_path("res://") + \
            PLATFORM_GRAPHS_DIRECTORY_NAME
