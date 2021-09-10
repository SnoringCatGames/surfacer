tool
class_name SurfacerLevel, \
"res://addons/scaffolder/assets/images/editor_icons/scaffolder_level.png"
extends ScaffolderLevel
## The main level class for Surfacer.[br]
## -   You should extend this with a sub-class for your specific game.[br]
## -   You should then attach your sub-class to each of your level scenes.[br]
## -   You should add a SurfacesTileMap child node to each of your level
##     scenes, in order to define the collidable surfaces in your level.[br]


var graph_parser: PlatformGraphParser
var surface_parser: SurfaceParser
var camera_pan_controller: CameraPanController
var intro_choreographer: Choreographer


func _init() -> void:
    graph_parser = PlatformGraphParser.new()
    surface_parser = graph_parser.surface_parser
    add_child(graph_parser)


func _load() -> void:
    ._load()
    
    Sc.gui.hud.create_inspector()
    
    graph_parser.parse(
            Sc.level_session.id,
            Su.is_debug_only_platform_graph_state_included)


func _start() -> void:
    ._start()
    
    camera_pan_controller = CameraPanController.new()
    add_child(camera_pan_controller)
    
    _execute_intro_choreography()
    
    call_deferred("_initialize_annotators")


#func _on_started() -> void:
#    ._on_started()


#func _add_player_character() -> void:
#    ._add_player_character()


#func _add_npcs() -> void:
#    ._add_npcs()


func _destroy() -> void:
    Sc.annotators.on_level_destroyed()
    
    if is_instance_valid(camera_pan_controller):
        camera_pan_controller._destroy()
    
    graph_parser.queue_free()
    
    ._destroy()


#func quit(
#        has_finished: bool,
#        immediately: bool) -> void:
#    .quit(has_finished, immediately)


#func _update_editor_configuration() -> void
#    ._update_editor_configuration()


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
    if !is_instance_valid(Sc.level.player_character):
        _on_intro_choreography_finished()
        return
    
    intro_choreographer = \
            Sc.level_config.get_intro_choreographer(Sc.level.player_character)
    
    if !is_instance_valid(intro_choreographer):
        _on_intro_choreography_finished()
        return
    
    intro_choreographer.connect(
            "finished", self, "_on_intro_choreography_finished")
    add_child(intro_choreographer)
    intro_choreographer.start()


func _on_intro_choreography_finished() -> void:
    if is_instance_valid(player_character):
        player_character._log(
                "Choreog done",
                "",
                CharacterLogType.DEFAULT,
                false)
    if is_instance_valid(intro_choreographer):
        intro_choreographer.queue_free()
        intro_choreographer = null
    _show_welcome_panel()


func _initialize_annotators() -> void:
    set_tile_map_visibility(false)
    set_background_visibility(false)
    Sc.annotators.on_level_ready()
    for group in [
            Sc.characters.GROUP_NAME_PLAYERS,
            Sc.characters.GROUP_NAME_NPCS]:
        for character in Sc.utils.get_all_nodes_in_group(group):
            character._on_annotators_ready()


func set_tile_map_visibility(is_visible: bool) -> void:
    var foregrounds: Array = Sc.utils.get_children_by_type(
            self,
            TileMap)
    for foreground in foregrounds:
        foreground.visible = is_visible


func set_background_visibility(is_visible: bool) -> void:
    var backgrounds: Array = Sc.utils.get_children_by_type(
            self,
            ParallaxBackground)
    for background in backgrounds:
        var layers: Array = Sc.utils.get_children_by_type(
            background,
            ParallaxLayer)
        for layer in layers:
            layer.visible = is_visible


func get_is_intro_choreography_running() -> bool:
    return intro_choreographer != null
