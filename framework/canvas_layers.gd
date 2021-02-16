extends Node2D
class_name CanvasLayers

const PLAYER_SUB_ANNOTATORS := [
    AnnotatorType.PLAYER_POSITION,
    AnnotatorType.PLAYER_TRAJECTORY,
    AnnotatorType.NAVIGATOR,
]

const LEVEL_SPECIFIC_ANNOTATORS := [
    AnnotatorType.LEVEL,
    AnnotatorType.GRID_INDICES,
    AnnotatorType.SURFACE_SELECTION,
]

var screen_layer: CanvasLayer
var menu_layer: CanvasLayer
var hud_layer: CanvasLayer
var ruler_layer: CanvasLayer
var annotation_layer: CanvasLayer

var ruler_annotator: RulerAnnotator
var grid_indices_annotator: GridIndicesAnnotator
var surface_selection_annotator: SurfaceSelectionAnnotator
var surface_preselection_annotator: SurfacePreselectionAnnotator
var click_annotator: ClickAnnotator

# Dictonary<Player, PlayerAnnotator>
var player_annotators := {}

var element_annotator: ElementAnnotator

var _annotator_enablement := {}

func _enter_tree() -> void:
    Global.canvas_layers = self
    
    _create_screen_layer()
    _create_menu_layer()
    _create_hud_layer()
    _create_ruler_layer()
    _create_annotation_layer()
    
    for annotator_type in Config.ANNOTATORS_DEFAULT_ENABLEMENT:
        set_annotator_enabled( \
                annotator_type, \
                Config.ANNOTATORS_DEFAULT_ENABLEMENT[annotator_type])

func on_level_ready() -> void:
    # Ensure any enabled annotators that depend on the level get drawn, now
    # that the level is available.
    for annotator_type in LEVEL_SPECIFIC_ANNOTATORS:
        if is_annotator_enabled(annotator_type):
            set_annotator_enabled( \
                    annotator_type, \
                    false)
            set_annotator_enabled( \
                    annotator_type, \
                    true)

func _process(delta_sec: float) -> void:
    # Transform the annotation layer to follow the camera.
    var camera: Camera2D = Global.camera_controller.get_current_camera()
    if camera != null:
        annotation_layer.transform = get_canvas_transform()

func _create_screen_layer() -> void:
    screen_layer = CanvasLayer.new()
    screen_layer.layer = 1000
    Global.add_overlay_to_current_scene(screen_layer)

func _create_menu_layer() -> void:
    menu_layer = CanvasLayer.new()
    menu_layer.layer = 400
    Global.add_overlay_to_current_scene(menu_layer)
    
    # TODO: Add start and pause menus.

func _create_hud_layer() -> void:
    hud_layer = CanvasLayer.new()
    hud_layer.layer = 300
    Global.add_overlay_to_current_scene(hud_layer)
    
    # TODO: Add HUD content.
    
    var utility_panel = Utils.add_scene( \
            hud_layer, \
            Config.UTILITY_PANEL_RESOURCE_PATH)
    Global.utility_panel = utility_panel
    
    var welcome_panel = Utils.add_scene( \
            hud_layer, \
            Config.WELCOME_PANEL_RESOURCE_PATH)
    Global.welcome_panel = welcome_panel

func _create_ruler_layer() -> void:
    ruler_layer = CanvasLayer.new()
    ruler_layer.layer = 200
    Global.add_overlay_to_current_scene(ruler_layer)

func _create_annotation_layer() -> void:
    annotation_layer = CanvasLayer.new()
    annotation_layer.layer = 100
    Global.add_overlay_to_current_scene(annotation_layer)
    
    element_annotator = ElementAnnotator.new()
    annotation_layer.add_child(element_annotator)
    Global.element_annotator = element_annotator

func _input(event: InputEvent) -> void:
    var current_time: float = Time.elapsed_play_time_actual_sec
    
    # Close the welcome panel on any mouse or key click event.
    if Global.welcome_panel != null and \
            (event is InputEventMouseButton or \
                    event is InputEventScreenTouch or \
                    event is InputEventKey) and \
            Global.is_level_ready:
        hud_layer.remove_child(Global.welcome_panel)
        Global.welcome_panel.queue_free()
        Global.welcome_panel = null

func create_player_annotator( \
        player: Player, \
        is_human_player: bool) -> void:
    var player_annotator := PlayerAnnotator.new( \
            player, \
            is_human_player)
    annotation_layer.add_child(player_annotator)
    player_annotators[player] = player_annotator
    
    for annotator_type in PLAYER_SUB_ANNOTATORS:
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
    
    if PLAYER_SUB_ANNOTATORS.find(annotator_type) >= 0:
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
            if Global.current_level != null and \
                    Global.current_level.surface_parser != null:
                grid_indices_annotator = GridIndicesAnnotator.new( \
                        Global.current_level.surface_parser)
                annotation_layer.add_child(grid_indices_annotator)
        AnnotatorType.CLICK:
            click_annotator = ClickAnnotator.new()
            annotation_layer.add_child(click_annotator)
        AnnotatorType.SURFACE_SELECTION:
            if Global.current_player_for_clicks != null:
                surface_selection_annotator = \
                        SurfaceSelectionAnnotator.new( \
                                Global.current_player_for_clicks)
                annotation_layer.add_child(surface_selection_annotator)
                surface_preselection_annotator = \
                        SurfacePreselectionAnnotator.new( \
                                Global.current_player_for_clicks)
                annotation_layer.add_child(surface_preselection_annotator)
        AnnotatorType.LEVEL:
            if Global.current_level != null:
                Global.current_level.set_level_visibility(true)
        _:
            Utils.error()

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
            if Global.current_level != null:
                Global.current_level.set_level_visibility(false)
        _:
            Utils.error()
