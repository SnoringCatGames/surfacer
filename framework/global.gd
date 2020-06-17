extends Node

const PLAYER_ACTIONS := {}

const EDGE_MOVEMENTS := {}

# Dictionary<String, PlayerParams>
var player_params := {}

var space_state: Physics2DDirectSpaceState

var canvas_layers: CanvasLayers
var current_level: Level
var current_player_for_clicks: Player
var camera_controller: CameraController
var element_annotator: ElementAnnotator
var platform_graph_inspector: PlatformGraphInspector
var legend: Legend
var selection_description: SelectionDescription
var utility_panel: UtilityPanel
var welcome_panel: WelcomePanel

var is_level_ready := false

func get_is_paused() -> bool:
    return get_tree().paused

func pause() -> void:
    get_tree().paused = true

func unpause() -> void:
    get_tree().paused = false

func register_player_actions(player_action_classes: Array) -> void:
    # Instantiate the various PlayerActions.
    for player_action_class in player_action_classes:
        PLAYER_ACTIONS[player_action_class.NAME] = player_action_class.new()

func register_edge_movements(edge_movement_classes: Array) -> void:
    # Instantiate the various EdgeMovements.
    for edge_movement_class in edge_movement_classes:
        EDGE_MOVEMENTS[edge_movement_class.NAME] = edge_movement_class.new()

func register_player_params(player_param_classes: Array) -> void:
    var player_params: PlayerParams
    for param_class in player_param_classes:
        player_params = PlayerParamsUtils.create_player_params(param_class)
        self.player_params[player_params.name] = player_params

func add_overlay_to_current_scene(node: Node) -> void:
    get_tree().get_current_scene().add_child(node)
