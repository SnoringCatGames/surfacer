class_name PlatformGraphParser
extends Node


signal calculation_started
signal load_started
signal calculation_progressed(
        character_index,
        character_count,
        origin_surface_index,
        surface_count)
signal parse_finished

const PLATFORM_GRAPHS_DIRECTORY_NAME := "platform_graphs"

var level_id: String
# The Tilemaps that define the collision boundaries of this level.
# Array<SurfacesTilemap>
var surface_tilemaps: Array
# Array<SurfaceMark>
var surface_marks: Array
# Dictionary<String, CrashTestDummy>
var crash_test_dummies := {}
var surface_parser := SurfaceParser.new()
var surface_store := SurfaceStore.new()
# Dictionary<String, PlatformGraph>
var platform_graphs: Dictionary
var is_loaded_from_file := false
var is_parse_finished := false


func parse(
        level_id: String,
        includes_debug_only_state: bool,
        force_calculation_from_tilemaps := false) -> void:
    self.level_id = level_id
    _record_tilemaps()
    _create_crash_test_dummies_for_collision_calculations()
    force_calculation_from_tilemaps = \
            force_calculation_from_tilemaps or \
            Su.ignores_platform_graph_save_files
    _instantiate_platform_graphs(
            includes_debug_only_state,
            force_calculation_from_tilemaps)


# Get references to the Tilemaps that define the collision boundaries of this
# level.
func _record_tilemaps() -> void:
    surface_tilemaps = Sc.utils.get_all_nodes_in_group(
            SurfacesTilemap.GROUP_NAME_SURFACES)
    surface_marks = Sc.utils.get_all_nodes_in_group(
            SurfaceMark.GROUP_NAME_SURFACE_MARKS)
    
    # Validate the Tilemaps.
    if Sc.metadata.debug or Sc.metadata.playtest:
        assert(surface_tilemaps.size() > 0)
        var tilemap_ids := {}
        for tile_map in surface_tilemaps:
            assert(tile_map is SurfacesTilemap)
            assert(tile_map.id != "" or surface_tilemaps.size() == 1)
            assert(!tilemap_ids.has(tile_map.id))
            tilemap_ids[tile_map.id] = true


func _create_crash_test_dummies_for_collision_calculations() -> void:
    for character_category_name in _get_character_category_names():
        var crash_test_dummy := CrashTestDummy.new(character_category_name)
        add_child(crash_test_dummy)
        crash_test_dummies[crash_test_dummy.character_category_name] = \
                crash_test_dummy


func _instantiate_platform_graphs(
        includes_debug_only_state: bool,
        force_calculation_from_tilemaps: bool) -> void:
    is_loaded_from_file = \
            !force_calculation_from_tilemaps and \
            File.new().file_exists(
                    _get_path(includes_debug_only_state))
    if is_loaded_from_file:
        emit_signal("load_started")
        Sc.time.set_timeout(
                funcref(self, "_load_platform_graphs"),
                0.01,
                [includes_debug_only_state])
    else:
        emit_signal("calculation_started")
        Sc.time.set_timeout(
                funcref(self, "_calculate_platform_graphs"),
                0.01)


func _on_graphs_parsed() -> void:
    if Su.is_inspector_enabled:
        Su.graph_inspector.set_graphs(platform_graphs.values())
    
    for platform_graph in platform_graphs.values():
        if platform_graph.is_connected(
                    "calculation_progressed",
                    self,
                    "_on_graph_calculation_progress"):
            platform_graph.disconnect(
                    "calculation_progressed",
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


func _calculate_platform_graphs() -> void:
    surface_parser.parse(
            surface_store,
            surface_tilemaps,
            surface_marks)
    platform_graphs = {}
    assert(!Su.movement.character_movement_params.empty())
    _defer_calculate_next_platform_graph(-1)


func _calculate_next_platform_graph(character_index: int) -> void:
    var platform_graph_character_category_names: Array = \
            _get_character_category_names()
    var character_category_name: String = \
            platform_graph_character_category_names[character_index]
    var is_last_character := \
            character_index == \
                platform_graph_character_category_names.size() - 1
    
    #######################################################################
    # Allow for debug mode to limit the scope of what's calculated.
    var should_skip_character: bool = \
            Su.debug_params.has("limit_parsing") and \
            Su.debug_params.limit_parsing.has("character_category_name") and \
            character_category_name != Su.debug_params.limit_parsing.character_category_name
    #######################################################################
    
    if !should_skip_character:
        var graph := PlatformGraph.new()
        graph.connect(
                "calculation_progressed",
                self,
                "_on_graph_calculation_progress",
                [graph, character_index, character_category_name])
        graph.connect(
                "calculation_finished",
                self,
                "_on_graph_calculation_finished",
                [character_index, is_last_character])
        graph.calculate(character_category_name)
        platform_graphs[character_category_name] = graph
    else:
        if !is_last_character:
            _calculate_next_platform_graph(character_index + 1)
        else:
            _on_graphs_parsed()


func _on_graph_calculation_progress(
        origin_surface_index,
        surface_count,
        graph: PlatformGraph,
        character_index: int,
        character_category_name: String) -> void:
    emit_signal(
            "calculation_progressed",
            character_index,
            _get_character_category_names().size(),
            origin_surface_index,
            surface_count)


func _on_graph_calculation_finished(
        character_index: int,
        was_last_character: bool) -> void:
    if !was_last_character:
        _defer_calculate_next_platform_graph(character_index)
    else:
        _on_graphs_parsed()


func _defer_calculate_next_platform_graph(last_character_index: int) -> void:
    Sc.time.set_timeout(
            funcref(self, "_calculate_next_platform_graph"),
            0.01,
            [last_character_index + 1])


func _load_platform_graphs(includes_debug_only_state: bool) -> void:
    var platform_graphs_path := _get_path(includes_debug_only_state)
    
    var json_object: Dictionary = \
            Sc.json.load_file(platform_graphs_path, false, false)
    
    var context := {
        id_to_tilemap = {},
        id_to_surface = {},
        id_to_position_along_surface = {},
        id_to_jump_land_positions = {},
    }
    for tile_map in surface_tilemaps:
        context.id_to_tilemap[tile_map.id] = tile_map
    
    surface_store.load_from_json_object(
            json_object.surface_parser,
            context,
            surface_parser)
    
    surface_marks = _deserialize_surface_marks(
            json_object.surface_marks,
            context)
    surface_store.marks = surface_marks
    
    if Sc.metadata.debug or Sc.metadata.playtest:
        _validate_tilemaps(json_object)
        _validate_characters(json_object)
        _validate_surfaces(surface_parser)
        _validate_platform_graphs(json_object)
    
    for graph_json_object in json_object.platform_graphs:
        var graph := PlatformGraph.new()
        graph.load_from_json_object(
                graph_json_object,
                context)
        platform_graphs[graph.character_category_name] = graph
    
    _on_graphs_parsed()


func _validate_tilemaps(json_object: Dictionary) -> void:
    var expected_id_set := {}
    for tile_map in surface_tilemaps:
        expected_id_set[tile_map.id] = true
    
    for id in json_object.surfaces_tilemap_ids:
        assert(expected_id_set.has(id))
        expected_id_set.erase(id)
    assert(expected_id_set.empty())


func _validate_characters(json_object: Dictionary) -> void:
    var expected_name_set := {}
    for character_category_name in _get_character_category_names():
        expected_name_set[character_category_name] = true
    
    for name in json_object.platform_graph_character_category_names:
        assert(expected_name_set.has(name))
        expected_name_set.erase(name)
    assert(expected_name_set.empty())


func _validate_surfaces(surface_parser: SurfaceParser) -> void:
    var expected_id_set := {}
    for tile_map in surface_tilemaps:
        expected_id_set[tile_map.id] = true
    
    for tile_map in surface_store._tilemap_index_to_surface_maps:
        assert(expected_id_set.has(tile_map.id))
        expected_id_set.erase(tile_map.id)
    assert(expected_id_set.empty())
    
    if Su.are_loaded_surfaces_deeply_validated:
        var expected_surface_store := SurfaceStore.new()
        surface_parser.parse(
                expected_surface_store,
                surface_tilemaps,
                surface_marks)
        
        assert(surface_store.max_tilemap_cell_size == \
                expected_surface_store.max_tilemap_cell_size)
        assert(surface_store.combined_tilemap_rect == \
                expected_surface_store.combined_tilemap_rect)
        
        assert(surface_store.floors.size() == \
                expected_surface_store.floors.size())
        assert(surface_store.ceilings.size() == \
                expected_surface_store.ceilings.size())
        assert(surface_store.left_walls.size() == \
                expected_surface_store.left_walls.size())
        assert(surface_store.right_walls.size() == \
                expected_surface_store.right_walls.size())
        
        for i in surface_store.floors.size():
            assert(surface_store.floors[i].probably_equal(
                    expected_surface_store.floors[i]))
        
        for i in surface_store.ceilings.size():
            assert(surface_store.ceilings[i].probably_equal(
                    expected_surface_store.ceilings[i]))
        
        for i in surface_store.left_walls.size():
            assert(surface_store.left_walls[i].probably_equal(
                    expected_surface_store.left_walls[i]))
        
        for i in surface_store.right_walls.size():
            assert(surface_store.right_walls[i].probably_equal(
                    expected_surface_store.right_walls[i]))
        
        for surface_mark in surface_marks:
            surface_mark.queue_free()


func _validate_platform_graphs(json_object: Dictionary) -> void:
    var expected_name_set := {}
    for character_category_name in _get_character_category_names():
        expected_name_set[character_category_name] = true
    
    for graph_json_object in json_object.platform_graphs:
        assert(expected_name_set \
                .has(graph_json_object.character_category_name))
        expected_name_set.erase(graph_json_object.character_category_name)
    
    assert(expected_name_set.empty())


func save_platform_graphs() -> void:
    assert(Sc.device.get_is_pc_app())
    
    if !Sc.utils.ensure_directory_exists(get_os_directory_path()):
        return
    
    var includes_debug_only_state := false
    var json_object := to_json_object(includes_debug_only_state)
    var path := _get_os_path(includes_debug_only_state)
    Sc.json.save_file(json_object, path, false)


func to_json_object(includes_debug_only_state: bool) -> Dictionary:
    return {
        level_id = level_id,
        surfaces_tilemap_ids = _get_surfaces_tilemap_ids(),
        surface_marks = _serialize_surface_marks(),
        platform_graph_character_category_names = \
                _get_character_category_names(),
        surface_parser = surface_store.to_json_object(),
        platform_graphs = \
                _serialize_platform_graphs(includes_debug_only_state),
    }


func _get_surfaces_tilemap_ids() -> Array:
    var result := []
    result.resize(surface_tilemaps.size())
    for i in surface_tilemaps.size():
        result[i] = surface_tilemaps[i].id
    return result


func _get_character_category_names() -> Array:
    return Sc.level_config.get_level_config(level_id) \
            .platform_graph_character_category_names


func _serialize_platform_graphs(includes_debug_only_state: bool) -> Array:
    var result := []
    for character_category_name in platform_graphs:
        result.push_back(platform_graphs[character_category_name] \
                .to_json_object(includes_debug_only_state))
    return result


func _serialize_surface_marks() -> Array:
    var result := surface_marks.duplicate()
    for i in result.size():
        result[i] = result[i].to_json_object()
    return result


func _deserialize_surface_marks(
        json_object: Array,
        context: Dictionary) -> Array:
    var result := json_object.duplicate()
    for i in result.size():
        var surface_mark := SurfaceMark.new()
        surface_mark.load_from_json_object(result[i], context)
        result[i] = surface_mark
    return result


func _get_path(includes_debug_only_state: bool) -> String:
    var file_name: String = "level_%s%s.json" % [
        level_id,
        ".debug" if includes_debug_only_state else "",
    ]
    return "res://%s%s/%s" % [
        Sc.metadata.base_path,
        PLATFORM_GRAPHS_DIRECTORY_NAME,
        file_name,
    ]


func _get_os_path(includes_debug_only_state: bool) -> String:
    var file_name: String = "level_%s%s.json" % [
        level_id,
        ".debug" if includes_debug_only_state else "",
    ]
    return "%s/%s" % [
        get_os_directory_path(),
        file_name,
    ]


static func get_os_directory_path() -> String:
    return ProjectSettings.globalize_path("res://") + \
            Sc.metadata.base_path + \
            PLATFORM_GRAPHS_DIRECTORY_NAME
