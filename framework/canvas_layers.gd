extends Node2D
class_name CanvasLayers

var global

var screen_layer: CanvasLayer
var menu_layer: CanvasLayer
var hud_layer: CanvasLayer
var ruler_layer: CanvasLayer
var annotation_layer: CanvasLayer

var ruler_annotator: RulerAnnotator
var platform_graph_annotator: PlatformGraphAnnotator
# Dictonary<Player, PlayerAnnotator>
var player_annotators := {}
var click_annotator: ClickAnnotator
var element_annotator: ElementAnnotator

func _enter_tree() -> void:
    self.global = $"/root/Global"
    self.global.canvas_layers = self
    
    _create_screen_layer()
    _create_menu_layer()
    _create_hud_layer()
    _create_ruler_layer()
    _create_annotation_layer()

func _process(delta: float) -> void:
    # Transform the annotation layer to follow the camera.
    var camera: Camera2D = global.camera_controller.get_current_camera()
    if camera != null:
        annotation_layer.transform = get_canvas_transform()

func _create_screen_layer() -> void:
    screen_layer = CanvasLayer.new()
    screen_layer.layer = 1000
    global.add_overlay_to_current_scene(screen_layer)

func _create_menu_layer() -> void:
    menu_layer = CanvasLayer.new()
    menu_layer.layer = 400
    global.add_overlay_to_current_scene(menu_layer)
    
    # TODO: Add start and pause menus.

func _create_hud_layer() -> void:
    hud_layer = CanvasLayer.new()
    hud_layer.layer = 300
    global.add_overlay_to_current_scene(hud_layer)
    
    # TODO: Add HUD content.
    
    var debug_panel = Utils.add_scene(hud_layer, Global.DEBUG_PANEL_RESOURCE_PATH)
    global.debug_panel = debug_panel
    
    var welcome_panel = Utils.add_scene(hud_layer, Global.WELCOME_PANEL_RESOURCE_PATH)
    global.welcome_panel = welcome_panel

func _create_ruler_layer() -> void:
    ruler_layer = CanvasLayer.new()
    ruler_layer.layer = 200
    global.add_overlay_to_current_scene(ruler_layer)
    
    ruler_annotator = RulerAnnotator.new(global)
    ruler_layer.add_child(ruler_annotator)

func _create_annotation_layer() -> void:
    annotation_layer = CanvasLayer.new()
    annotation_layer.layer = 100
    global.add_overlay_to_current_scene(annotation_layer)
    
    click_annotator = ClickAnnotator.new()
    annotation_layer.add_child(click_annotator)
    
    element_annotator = ElementAnnotator.new()
    annotation_layer.add_child(element_annotator)
    global.element_annotator = element_annotator

func _input(event: InputEvent) -> void:
    var current_time: float = global.elapsed_play_time_sec
    
    # Close the welcome panel on any mouse or key click event.
    if global.welcome_panel != null and \
            (event is InputEventMouseButton or event is InputEventKey):
        hud_layer.remove_child(global.welcome_panel)
        global.welcome_panel.queue_free()
        global.welcome_panel = null

func create_graph_annotator(graph: PlatformGraph) -> void:
    platform_graph_annotator = PlatformGraphAnnotator.new(graph)
    annotation_layer.add_child(platform_graph_annotator)

func create_player_annotator( \
        player: Player, \
        is_human_player: bool) -> void:
    var player_annotator := PlayerAnnotator.new(player, !is_human_player)
    annotation_layer.add_child(player_annotator)
    player_annotators[player] = player_annotator
