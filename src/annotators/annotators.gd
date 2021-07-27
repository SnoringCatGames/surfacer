tool
class_name Annotators
extends Node2D


var _PLAYER_SUB_ANNOTATORS := [
    AnnotatorType.PLAYER,
    AnnotatorType.PLAYER_POSITION,
    AnnotatorType.RECENT_MOVEMENT,
    AnnotatorType.NAVIGATOR,
]

var _LEVEL_SPECIFIC_ANNOTATORS := [
    AnnotatorType.RULER,
    AnnotatorType.LEVEL,
    AnnotatorType.SURFACES,
    AnnotatorType.GRID_INDICES,
    AnnotatorType.PATH_PRESELECTION,
]

# Dictionary<AnnotatorType, bool>
const _DEFAULT_ENABLEMENT := {
    AnnotatorType.RULER: false,
    AnnotatorType.SURFACES: false,
    AnnotatorType.GRID_INDICES: false,
    AnnotatorType.LEVEL: true,
    AnnotatorType.PLAYER: true,
    AnnotatorType.PLAYER_POSITION: false,
    AnnotatorType.RECENT_MOVEMENT: true,
    AnnotatorType.NAVIGATOR: true,
    AnnotatorType.PATH_PRESELECTION: true,
}

var ruler_annotator: RulerAnnotator
var surfaces_annotator: SurfacesAnnotator
var grid_indices_annotator: GridIndicesAnnotator
var path_preselection_annotator: PathPreselectionAnnotator

# Dictonary<Player, PlayerAnnotator>
var player_annotators := {}

var element_annotator: ElementAnnotator

var transient_annotator_registry: TransientAnnotatorRegistry

var _annotator_enablement := {}

var annotation_layer: CanvasLayer
var ruler_layer: CanvasLayer


func _init() -> void:
    Sc.logger.on_global_init(self, "Annotators")
    if Engine.editor_hint:
        return
    annotation_layer = Sc.canvas_layers.layers.annotation


func _ready() -> void:
    if Engine.editor_hint:
        return
    
    ruler_layer = Sc.canvas_layers.create_layer(
            "ruler",
            annotation_layer.layer + 5,
            Node.PAUSE_MODE_STOP)
    
    element_annotator = ElementAnnotator.new()
    annotation_layer.add_child(element_annotator)
    
    transient_annotator_registry = TransientAnnotatorRegistry.new()
    annotation_layer.add_child(transient_annotator_registry)
    
    for annotator_type in _DEFAULT_ENABLEMENT:
        var is_enabled: bool = Sc.save_state.get_setting(
                AnnotatorType.get_settings_key(annotator_type),
                _DEFAULT_ENABLEMENT[annotator_type])
        set_annotator_enabled(
                annotator_type,
                is_enabled)


func _on_app_initialized() -> void:
    if Engine.editor_hint:
        return
    
    Sc.nav.screens["game"].move_canvas_layer_to_game_viewport("ruler")


func on_level_ready() -> void:
    # Ensure any enabled annotators that depend on the level get drawn, now
    # that the level is available.
    for annotator_type in _LEVEL_SPECIFIC_ANNOTATORS:
        if is_annotator_enabled(annotator_type):
            set_annotator_enabled(
                    annotator_type,
                    false)
            set_annotator_enabled(
                    annotator_type,
                    true)


func on_level_destroyed() -> void:
    element_annotator.clear()
    transient_annotator_registry.clear()
    for annotator_type in _LEVEL_SPECIFIC_ANNOTATORS:
        if is_annotator_enabled(annotator_type):
            _destroy_annotator(annotator_type)
    for player in player_annotators.keys():
        destroy_player_annotator(player)


func create_player_annotator(
        player: Player,
        is_human_player: bool) -> void:
    var player_annotator := PlayerAnnotator.new(
            player,
            is_human_player)
    annotation_layer.add_child(player_annotator)
    player_annotators[player] = player_annotator
    
    for annotator_type in _PLAYER_SUB_ANNOTATORS:
        player_annotator.set_annotator_enabled(
                annotator_type,
                _annotator_enablement[annotator_type])


func destroy_player_annotator(player: Player) -> void:
    if !player_annotators.has(player):
        return
    player_annotators[player].queue_free()
    player_annotators.erase(player)


func get_player_annotator(player: Player) -> PlayerAnnotator:
    return player_annotators[player]


func set_annotator_enabled(
        annotator_type: int,
        is_enabled: bool) -> void:
    if is_annotator_enabled(annotator_type) == is_enabled:
        # Do nothing. The annotator is already correct.
        return
    
    if _PLAYER_SUB_ANNOTATORS.find(annotator_type) >= 0:
        for player_annotator in player_annotators.values():
            player_annotator.set_annotator_enabled(
                    annotator_type,
                    is_enabled)
    else:
        if is_enabled:
            _create_annotator(annotator_type)
        else:
            _destroy_annotator(annotator_type)
    
    _annotator_enablement[annotator_type] = is_enabled


func is_annotator_enabled(annotator_type: int) -> bool:
    if !_annotator_enablement.has(annotator_type):
        _annotator_enablement[annotator_type] = false
    return _annotator_enablement[annotator_type]


func _create_annotator(annotator_type: int) -> void:
    assert(!is_annotator_enabled(annotator_type))
    match annotator_type:
        AnnotatorType.RULER:
            if Sc.level != null:
                ruler_annotator = RulerAnnotator.new()
                ruler_layer.add_child(ruler_annotator)
        AnnotatorType.SURFACES:
            if Sc.level != null and \
                    Su.graph_parser.surface_parser != null:
                surfaces_annotator = SurfacesAnnotator.new( \
                        Su.graph_parser.surface_parser)
                annotation_layer.add_child(surfaces_annotator)
        AnnotatorType.GRID_INDICES:
            if Sc.level != null and \
                    Su.graph_parser.surface_parser != null:
                grid_indices_annotator = GridIndicesAnnotator.new(
                        Su.graph_parser.surface_parser)
                annotation_layer.add_child(grid_indices_annotator)
        AnnotatorType.PATH_PRESELECTION:
            if Su.human_player != null:
                path_preselection_annotator = \
                        PathPreselectionAnnotator.new(Su.human_player)
                annotation_layer.add_child(path_preselection_annotator)
        AnnotatorType.LEVEL:
            if Sc.level != null:
                Sc.level.set_tile_map_visibility(true)
        _:
            Sc.logger.error()


func _destroy_annotator(annotator_type: int) -> void:
    assert(is_annotator_enabled(annotator_type))
    match annotator_type:
        AnnotatorType.RULER:
            if ruler_annotator != null:
                ruler_annotator.queue_free()
                ruler_annotator = null
        AnnotatorType.SURFACES:
            if surfaces_annotator != null:
                surfaces_annotator.queue_free()
                surfaces_annotator = null
        AnnotatorType.GRID_INDICES:
            if grid_indices_annotator != null:
                grid_indices_annotator.queue_free()
                grid_indices_annotator = null
        AnnotatorType.PATH_PRESELECTION:
            if path_preselection_annotator != null:
                path_preselection_annotator.queue_free()
                path_preselection_annotator = null
        AnnotatorType.LEVEL:
            if Sc.level != null:
                Sc.level.set_tile_map_visibility(false)
        _:
            Sc.logger.error()


func add_transient(annotator: TransientAnnotator) -> void:
    transient_annotator_registry.add(annotator)
