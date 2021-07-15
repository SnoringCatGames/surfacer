class_name SurfacerBootstrap
extends ScaffolderBootstrap


func _init().("SurfacerBootstrap") -> void:
    pass


func _initialize_framework() -> void:
    ._initialize_framework()
    
    _register_player_actions(Su.player_action_classes)
    _register_edge_movements(Su.edge_movement_classes)
    _register_player_params(Su.player_param_classes)


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


func _register_player_actions(player_action_classes: Array) -> void:
    # Instantiate the various PlayerActions.
    for player_action_class in player_action_classes:
        Su.player_actions[player_action_class.NAME] = \
                player_action_class.new()


func _register_edge_movements(edge_movement_classes: Array) -> void:
    # Instantiate the various EdgeMovements.
    for edge_movement_class in edge_movement_classes:
        Su.edge_movements[edge_movement_class.NAME] = \
                edge_movement_class.new()


func _register_player_params(player_param_classes: Array) -> void:
    for param_class in player_param_classes:
        var player_params: PlayerParams = \
                PlayerParamsUtils.create_player_params(param_class)
        Su.player_params[player_params.name] = player_params
