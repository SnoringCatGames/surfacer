class_name SurfacerLevel
extends ScaffolderLevel


# Array<SurfacerPlayer>
var all_players: Array
var camera_pan_controller: CameraPanController
var intro_choreographer: Choreographer


func _init() -> void:
    var graph_parser := PlatformGraphParser.new()
    add_child(graph_parser)


func _load() -> void:
    ._load()
    
    Sc.gui.hud.create_inspector()
    
    Su.graph_parser.parse(
            Sc.level_session.id,
            Su.is_debug_only_platform_graph_state_included)


func _start() -> void:
    ._start()
    
    camera_pan_controller = CameraPanController.new()
    add_child(camera_pan_controller)
    
    add_player(
            Su.player_scenes[Su.default_player_name],
            get_player_start_position(),
            true)
    _execute_intro_choreography()
    
    call_deferred("_initialize_annotators")


func _destroy() -> void:
    for group in [
            Su.group_name_human_players,
            Su.group_name_computer_players]:
        for player in Sc.utils.get_all_nodes_in_group(group):
            player._destroy()
    
    Su.annotators.on_level_destroyed()
    Su.human_player = null
    
    if is_instance_valid(camera_pan_controller):
        camera_pan_controller._destroy()
    
    ._destroy()


#func quit(
#        has_finished: bool,
#        immediately: bool) -> void:
#    .quit(has_finished, immediately)


#func _update_editor_configuration() -> void
#    ._update_editor_configuration()


func _unhandled_input(event: InputEvent) -> void:
    if Engine.editor_hint:
        return
    
    if event is InputEventMouseButton or \
            event is InputEventScreenTouch:
        # This ensures that pressing arrow keys won't change selections in the
        # inspector.
        Sc.utils.release_focus()


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
            Sc.level_config.get_intro_choreographer(Su.human_player)
    intro_choreographer.connect(
            "finished", self, "_on_intro_choreography_finished")
    add_child(intro_choreographer)
    intro_choreographer.start()


func _on_intro_choreography_finished() -> void:
    Sc.logger.print("Intro choreography finished")
    intro_choreographer.queue_free()
    intro_choreographer = null
    _show_welcome_panel()


func get_slow_motion_music_name() -> String:
    return ""


func _initialize_annotators() -> void:
    set_tile_map_visibility(false)
    Su.annotators.on_level_ready()
    for group in [
            Su.group_name_human_players,
            Su.group_name_computer_players]:
        for player in Sc.utils.get_all_nodes_in_group(group):
            player._on_annotators_ready()


func add_player(
        path_or_packed_scene,
        position: Vector2,
        is_human_player: bool) -> SurfacerPlayer:
    var player: SurfacerPlayer = Sc.utils.add_scene(
            self,
            path_or_packed_scene,
            false,
            true)
    player.set_position(position)
    all_players.push_back(player)
    add_child(player)
    
    var group: String = \
            Su.group_name_human_players if \
            is_human_player else \
            Su.group_name_computer_players
    player.add_to_group(group)
    
    var graph = _get_platform_graph_for_player(player.player_name)
    if graph != null:
        player.set_platform_graph(graph)
    
    if is_human_player:
        player.init_human_player_state()
        Su.human_player = player
    else:
        player.init_computer_player_state()
    
    # Set up some annotators to help with debugging.
    player.set_is_sprite_visible(false)
    Su.annotators.create_player_annotator(
            player,
            is_human_player)
    
    return player


func remove_player(player: SurfacerPlayer) -> void:
    var group: String = \
            Su.group_name_human_players if \
            player.is_human_player else \
            Su.group_name_computer_players
    player.remove_from_group(group)
    Su.annotators.destroy_player_annotator(player)
    player._destroy()


func set_tile_map_visibility(is_visible: bool) -> void:
    # TODO: Also show/hide background. Parallax doesn't extend from CanvasItem
    #       or have the `visible` field though.
#    var backgrounds := Sc.utils.get_children_by_type(
#            self,
#            ParallaxBackground)
    var foregrounds: Array = Sc.utils.get_children_by_type(
            self,
            TileMap)
    for node in foregrounds:
        node.visible = is_visible


func _get_platform_graph_for_player(player_name: String) -> PlatformGraph:
    return Su.graph_parser.platform_graphs[player_name]


func get_player_start_position() -> Vector2:
    var nodes: Array = Sc.utils.get_all_nodes_in_group(
            SurfacerLevelConfig.PLAYER_START_POSITION_GROUP_NAME)
    if nodes.empty():
        return Vector2.ZERO
    else:
        return nodes[0].position


func get_is_intro_choreography_running() -> bool:
    return intro_choreographer != null
