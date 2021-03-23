extends Node2D
class_name Annotators

var _PLAYER_SUB_ANNOTATORS := [
    AnnotatorType.PLAYER_POSITION,
    AnnotatorType.PLAYER_TRAJECTORY,
    AnnotatorType.NAVIGATOR,
]

var _LEVEL_SPECIFIC_ANNOTATORS := [
    AnnotatorType.LEVEL,
    AnnotatorType.GRID_INDICES,
    AnnotatorType.SURFACE_SELECTION,
]

# Dictionary<AnnotatorType, bool>
const _DEFAULT_ENABLEMENT := {
    AnnotatorType.RULER: false,
    AnnotatorType.GRID_INDICES: false,
    AnnotatorType.LEVEL: true,
    AnnotatorType.PLAYER_POSITION: false,
    AnnotatorType.PLAYER_TRAJECTORY: true,
    AnnotatorType.NAVIGATOR: true,
    AnnotatorType.CLICK: true,
    AnnotatorType.SURFACE_SELECTION: true,
}

var ruler_annotator: RulerAnnotator
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
    ruler_layer = Gs.canvas_layers.create_layer( \
            "ruler", \
            annotation_layer.layer + 5, \
            Node.PAUSE_MODE_STOP)
    Gs.nav.screens["game"].move_canvas_layer_to_game_viewport("ruler")
    
    element_annotator = ElementAnnotator.new()
    annotation_layer.add_child(element_annotator)
    
    for annotator_type in _DEFAULT_ENABLEMENT:
        set_annotator_enabled( \
                annotator_type, \
                _DEFAULT_ENABLEMENT[annotator_type])

func on_level_ready() -> void:
    # Ensure any enabled annotators that depend on the level get drawn, now
    # that the level is available.
    for annotator_type in _LEVEL_SPECIFIC_ANNOTATORS:
        if is_annotator_enabled(annotator_type):
            set_annotator_enabled( \
                    annotator_type, \
                    false)
            set_annotator_enabled( \
                    annotator_type, \
                    true)

func create_player_annotator( \
        player: Player, \
        is_human_player: bool) -> void:
    var player_annotator := PlayerAnnotator.new( \
            player, \
            is_human_player)
    annotation_layer.add_child(player_annotator)
    player_annotators[player] = player_annotator
    
    for annotator_type in _PLAYER_SUB_ANNOTATORS:
        player_annotator.set_annotator_enabled( \
                annotator_type, \
                _annotator_enablement[annotator_type])

func destroy_player_annotator(player: Player) -> void:
    annotation_layer.remove_child(player_annotators[player])
    player_annotators[player].queue_free()
    player_annotators.erase(player)

func set_annotator_enabled( \
        annotator_type: int, \
        is_enabled: bool) -> void:
    if is_annotator_enabled(annotator_type) == is_enabled:
        # Do nothing. The annotator is already correct.
        return
    
    if _PLAYER_SUB_ANNOTATORS.find(annotator_type) >= 0:
        for player_annotator in player_annotators.values():
            player_annotator.set_annotator_enabled( \
                    annotator_type, \
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
        AnnotatorType.GRID_INDICES:
            if Gs.level != null and \
                    Gs.level.surface_parser != null:
                grid_indices_annotator = GridIndicesAnnotator.new( \
                        Gs.level.surface_parser)
                annotation_layer.add_child(grid_indices_annotator)
        AnnotatorType.CLICK:
            click_annotator = ClickAnnotator.new()
            annotation_layer.add_child(click_annotator)
        AnnotatorType.SURFACE_SELECTION:
            if SurfacerConfig.current_player_for_clicks != null:
                surface_selection_annotator = \
                        SurfaceSelectionAnnotator.new( \
                                SurfacerConfig.current_player_for_clicks)
                annotation_layer.add_child(surface_selection_annotator)
                surface_preselection_annotator = \
                        SurfacePreselectionAnnotator.new( \
                                SurfacerConfig.current_player_for_clicks)
                annotation_layer.add_child(surface_preselection_annotator)
        AnnotatorType.LEVEL:
            if Gs.level != null:
                Gs.level.set_level_visibility(true)
        _:
            Gs.utils.static_error()

func _destroy_annotator(annotator_type: int) -> void:
    assert(is_annotator_enabled(annotator_type))
    match annotator_type:
        AnnotatorType.RULER:
            if ruler_annotator != null:
                ruler_layer.remove_child(ruler_annotator)
                ruler_annotator.queue_free()
                ruler_annotator = null
        AnnotatorType.GRID_INDICES:
            if grid_indices_annotator != null:
                annotation_layer.remove_child(grid_indices_annotator)
                grid_indices_annotator.queue_free()
                grid_indices_annotator = null
        AnnotatorType.CLICK:
            if click_annotator != null:
                annotation_layer.remove_child(click_annotator)
                click_annotator.queue_free()
                click_annotator = null
        AnnotatorType.SURFACE_SELECTION:
            if surface_selection_annotator != null:
                annotation_layer.remove_child(surface_selection_annotator)
                surface_selection_annotator.queue_free()
                surface_selection_annotator = null
                annotation_layer.remove_child(surface_preselection_annotator)
                surface_preselection_annotator.queue_free()
                surface_preselection_annotator = null
        AnnotatorType.LEVEL:
            if Gs.level != null:
                Gs.level.set_level_visibility(false)
        _:
            Gs.utils.static_error()
