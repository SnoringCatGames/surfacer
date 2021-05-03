class_name Annotators
extends Node2D

var _PLAYER_SUB_ANNOTATORS := [
    AnnotatorType.PLAYER,
    AnnotatorType.PLAYER_POSITION,
    AnnotatorType.PLAYER_TRAJECTORY,
    AnnotatorType.NAVIGATOR,
]

var _LEVEL_SPECIFIC_ANNOTATORS := [
    AnnotatorType.LEVEL,
    AnnotatorType.SURFACES,
    AnnotatorType.GRID_INDICES,
    AnnotatorType.SURFACE_SELECTION,
]

# Dictionary<AnnotatorType, bool>
const _DEFAULT_ENABLEMENT := {
    AnnotatorType.RULER: false,
    AnnotatorType.SURFACES: false,
    AnnotatorType.GRID_INDICES: false,
    AnnotatorType.LEVEL: true,
    AnnotatorType.PLAYER: true,
    AnnotatorType.PLAYER_POSITION: false,
    AnnotatorType.PLAYER_TRAJECTORY: true,
    AnnotatorType.NAVIGATOR: true,
    AnnotatorType.CLICK: true,
    AnnotatorType.SURFACE_SELECTION: true,
}

var ruler_annotator: RulerAnnotator
var surfaces_annotator: SurfacesAnnotator
var grid_indices_annotator: GridIndicesAnnotator
var surface_selection_annotator: SurfaceSelectionAnnotator
var surface_preselection_annotator: SurfacePreselectionAnnotator
var click_annotator: ClickAnnotator

# Dictonary<Player, PlayerAnnotator>
var player_annotators := {}

var element_annotator: ElementAnnotator

var _annotator_enablement := {}

var annotation_layer: CanvasLayer
var ruler_layer: CanvasLayer

func _init() -> void:
    name = "Annotators"
    annotation_layer = Gs.canvas_layers.layers.annotation

func _enter_tree() -> void:
    ruler_layer = Gs.canvas_layers.create_layer(
            "ruler",
            annotation_layer.layer + 5,
            Node.PAUSE_MODE_STOP)
    Gs.nav.screens["game"].move_canvas_layer_to_game_viewport("ruler")
    
    element_annotator = ElementAnnotator.new()
    annotation_layer.add_child(element_annotator)
    
    for annotator_type in _DEFAULT_ENABLEMENT:
        var is_enabled: bool = Gs.save_state.get_setting(
                AnnotatorType.get_settings_key(annotator_type),
                _DEFAULT_ENABLEMENT[annotator_type])
        set_annotator_enabled(
                annotator_type,
                is_enabled)

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
    Surfacer.annotators.element_annotator.clear()
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
    player_annotators[player].queue_free()
    player_annotators.erase(player)

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
            ruler_annotator = RulerAnnotator.new()
            ruler_layer.add_child(ruler_annotator)
        AnnotatorType.SURFACES:
            if Gs.level != null and \
                    Surfacer.graph_parser.surface_parser != null:
                surfaces_annotator = SurfacesAnnotator.new( \
                        Surfacer.graph_parser.surface_parser)
                annotation_layer.add_child(surfaces_annotator)
        AnnotatorType.GRID_INDICES:
            if Gs.level != null and \
                    Surfacer.graph_parser.surface_parser != null:
                grid_indices_annotator = GridIndicesAnnotator.new(
                        Surfacer.graph_parser.surface_parser)
                annotation_layer.add_child(grid_indices_annotator)
        AnnotatorType.CLICK:
            click_annotator = ClickAnnotator.new()
            annotation_layer.add_child(click_annotator)
        AnnotatorType.SURFACE_SELECTION:
            if Surfacer.current_player_for_clicks != null:
                surface_selection_annotator = \
                        SurfaceSelectionAnnotator.new(
                                Surfacer.current_player_for_clicks)
                annotation_layer.add_child(surface_selection_annotator)
                surface_preselection_annotator = \
                        SurfacePreselectionAnnotator.new(
                                Surfacer.current_player_for_clicks)
                annotation_layer.add_child(surface_preselection_annotator)
        AnnotatorType.LEVEL:
            if Gs.level != null:
                Gs.level.set_tile_map_visibility(true)
        _:
            Gs.logger.error()

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
        AnnotatorType.CLICK:
            if click_annotator != null:
                click_annotator.queue_free()
                click_annotator = null
        AnnotatorType.SURFACE_SELECTION:
            if surface_selection_annotator != null:
                surface_selection_annotator.queue_free()
                surface_selection_annotator = null
                surface_preselection_annotator.queue_free()
                surface_preselection_annotator = null
        AnnotatorType.LEVEL:
            if Gs.level != null:
                Gs.level.set_tile_map_visibility(false)
        _:
            Gs.logger.error()
