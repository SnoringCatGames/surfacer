extends Node
class_name SurfacerBootstrap

func _init() -> void:
    Gs.utils.print("SurfacerBootstrap._init")

func on_app_ready( \
        app_manifest: Dictionary, \
        main: Node) -> void:
    var scaffold_bootstrap := ScaffoldBootstrap.new()
    scaffold_bootstrap.on_app_ready(app_manifest, main)
    
    SurfacerConfig.annotators = Annotators.new()
    main.add_child(SurfacerConfig.annotators)
    
    register_player_actions(SurfacerConfig.player_action_classes)
    register_edge_movements(SurfacerConfig.edge_movement_classes)
    register_player_params(SurfacerConfig.player_param_classes)

func register_player_actions(player_action_classes: Array) -> void:
    # Instantiate the various PlayerActions.
    for player_action_class in player_action_classes:
        SurfacerConfig.player_actions[player_action_class.NAME] = \
                player_action_class.new()

func register_edge_movements(edge_movement_classes: Array) -> void:
    # Instantiate the various EdgeMovements.
    for edge_movement_class in edge_movement_classes:
        SurfacerConfig.edge_movements[edge_movement_class.NAME] = \
                edge_movement_class.new()

func register_player_params(player_param_classes: Array) -> void:
    for param_class in player_param_classes:
        var player_params: PlayerParams = \
                PlayerParamsUtils.create_player_params(param_class)
        SurfacerConfig.player_params[player_params.name] = player_params
