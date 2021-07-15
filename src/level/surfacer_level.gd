class_name SurfacerLevel
extends ScaffolderLevel


# Array<Player>
var all_players: Array
var camera_pan_controller: CameraPanController
var intro_choreographer: Choreographer


func _init() -> void:
    var graph_parser := PlatformGraphParser.new()
    add_child(graph_parser)


func _load() -> void:
    ._load()
    
    Gs.gui.hud.create_inspector()
    
    Surfacer.graph_parser.parse(
            Gs.level_session.id,
            Surfacer.is_debug_only_platform_graph_state_included)


func _start() -> void:
    ._start()
    
    camera_pan_controller = CameraPanController.new()
    add_child(camera_pan_controller)
    
    add_player(
            Surfacer.player_params[Surfacer.default_player_name] \
                    .movement_params.player_path_or_scene,
            get_player_start_position(),
            true)
    _execute_intro_choreography()
    
    call_deferred("_initialize_annotators")


func _destroy() -> void:
    for group in [
            Surfacer.group_name_human_players,
            Surfacer.group_name_computer_players]:
        for player in Gs.utils.get_all_nodes_in_group(group):
            player._destroy()
    
    Surfacer.annotators.on_level_destroyed()
    Surfacer.human_player = null
    
    if is_instance_valid(camera_pan_controller):
        camera_pan_controller._destroy()
    
    ._destroy()


#func quit(
#        has_finished: bool,
#        immediately: bool) -> void:
#    .quit(has_finished, immediately)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton or \
            event is InputEventScreenTouch:
        # This ensures that pressing arrow keys won't change selections in the
        # inspector.
        Gs.utils.release_focus()


func _on_initial_input() -> void:
    ._on_initial_input()

    if is_instance_valid(intro_choreographer):
        intro_choreographer.on_interaction()


#func pause() -> void:
#    .pause()


#func on_unpause() -> void:
#    .on_unpause()


# Execute any intro cut-scene or initial navigation.
func _execute_intro_choreography() -> void:
    intro_choreographer = \
            Gs.level_config.get_intro_choreographer(Surfacer.human_player)
    intro_choreographer.connect(
            "finished", self, "_on_intro_choreography_finished")
    add_child(intro_choreographer)
    intro_choreographer.start()


func _on_intro_choreography_finished() -> void:
    Gs.logger.print("Intro choreography finished")
    intro_choreographer.queue_free()
    intro_choreographer = null
    _show_welcome_panel()


func get_slow_motion_music_name() -> String:
    return ""


func _initialize_annotators() -> void:
    set_tile_map_visibility(false)
    Surfacer.annotators.on_level_ready()
    for group in [
            Surfacer.group_name_human_players,
            Surfacer.group_name_computer_players]:
        for player in Gs.utils.get_all_nodes_in_group(group):
            player._on_annotators_ready()


func add_player(
        path_or_packed_scene,
        position: Vector2,
        is_human_player: bool) -> Player:
    var player: Player = Gs.utils.add_scene(
            self,
            path_or_packed_scene,
            false,
            true)
    player.set_position(position)
    add_child(player)
    
    var group: String = \
            Surfacer.group_name_human_players if \
            is_human_player else \
            Surfacer.group_name_computer_players
    player.add_to_group(group)
    
    var graph = _get_platform_graph_for_player(player.player_name)
    if graph != null:
        player.set_platform_graph(graph)
    
    if is_human_player:
        player.init_human_player_state()
        Surfacer.human_player = player
    else:
        player.init_computer_player_state()
    
    # Set up some annotators to help with debugging.
    player.set_is_sprite_visible(false)
    Surfacer.annotators.create_player_annotator(
            player,
            is_human_player)
    
    return player


func remove_player(player: Player) -> void:
    var group: String = \
            Surfacer.group_name_human_players if \
            player.is_human_player else \
            Surfacer.group_name_computer_players
    player.remove_from_group(group)
    Surfacer.annotators.destroy_player_annotator(player)
    player._destroy()


func set_tile_map_visibility(is_visible: bool) -> void:
    # TODO: Also show/hide background. Parallax doesn't extend from CanvasItem
    #       or have the `visible` field though.
#    var backgrounds := Gs.utils.get_children_by_type(
#            self,
#            ParallaxBackground)
    var foregrounds: Array = Gs.utils.get_children_by_type(
            self,
            TileMap)
    for node in foregrounds:
        node.visible = is_visible


func _get_platform_graph_for_player(player_name: String) -> PlatformGraph:
    return Surfacer.graph_parser.platform_graphs[player_name]


func get_player_start_position() -> Vector2:
    var nodes: Array = Gs.utils.get_all_nodes_in_group(
            SurfacerLevelConfig.PLAYER_START_POSITION_GROUP_NAME)
    if nodes.empty():
        return Vector2.ZERO
    else:
        return nodes[0].position


func get_is_intro_choreography_running() -> bool:
    return intro_choreographer != null
