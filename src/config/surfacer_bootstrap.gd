tool
class_name SurfacerBootstrap
extends ScaffolderBootstrap


func _init().("SurfacerBootstrap") -> void:
    pass


func _initialize_framework() -> void:
    ._initialize_framework()
    
    _parse_player_scenes(Su._player_scenes_list)
    _register_action_handlers(Su.movement._action_handler_classes)
    _register_edge_calculators(Su.movement._edge_calculator_classes)


func _on_app_initialized() -> void:
    ._on_app_initialized()
    Su.annotators._on_app_initialized()
    # Hide this annotator by default.
    Su.annotators.set_annotator_enabled(
            AnnotatorType.RECENT_MOVEMENT,
            false)


func _on_splash_finished() -> void:
    if !Su.is_precomputing_platform_graphs:
        ._on_splash_finished()
    else:
        Sc.nav.open("precompute_platform_graphs")


func _register_action_handlers(action_handler_classes: Array) -> void:
    # Instantiate the various PlayerActions.
    for action_handler_class in action_handler_classes:
        Su.movement.action_handlers[action_handler_class.NAME] = \
                action_handler_class.new()


func _register_edge_calculators(edge_calculator_classes: Array) -> void:
    # Instantiate the various EdgeMovements.
    for edge_calculator_class in edge_calculator_classes:
        Su.movement.edge_calculators[edge_calculator_class.NAME] = \
                edge_calculator_class.new()


func _parse_player_scenes(scenes_array: Array) -> void:
    # FIXME: ----------------------------------------------------
    print(">>>>>>>>>>>>SurfacerBootstrap._parse_player_scenes %s" % scenes_array.size())
    # FIXME: ----------------- Test this
    for scene in scenes_array:
        assert(scene is PackedScene)
        var state: SceneState = scene.get_state()
        assert(state.get_node_type(0) == "KinematicBody2D")
        
        var player_name: String = \
                Sc.utils.get_property_value_from_scene_state_node(
                        state,
                        0,
                        "player_name",
                        !Engine.editor_hint)
        var movement_params: MovementParams = \
                Sc.utils.get_property_value_from_scene_state_node(
                        state,
                        0,
                        "movement_params",
                        !Engine.editor_hint)
        
        Su.player_scenes[player_name] = scene
        Su.movement.player_movement_params[player_name] = movement_params
