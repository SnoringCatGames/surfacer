extends Screen
class_name GameScreen

const NAME := "game"
const LAYER_NAME := "game_screen"
const INCLUDES_STANDARD_HIERARCHY := false

var level: ScaffoldLevel

func _init().( \
        NAME, \
        LAYER_NAME, \
        INCLUDES_STANDARD_HIERARCHY \
        ) -> void:
    pass

func _enter_tree() -> void:
    move_canvas_layer_to_game_viewport("annotation")
    
    ScaffoldUtils.connect( \
            "display_resized", \
            self, \
            "_update_viewport_region")
    _update_viewport_region()

func move_canvas_layer_to_game_viewport(name: String) -> void:
    var layer: CanvasLayer = ScaffoldConfig.canvas_layers.layers[name]
    layer.get_parent().remove_child(layer)
    $PanelContainer/ViewportContainer/Viewport.add_child(layer)

func _process(_delta_sec: float) -> void:
    if !is_instance_valid(level):
        return
    
    # Transform the annotation layer to follow the camera within the
    # game-screen viewport.
    ScaffoldConfig.canvas_layers.layers.annotation.transform = \
            level.get_canvas_transform()

func _update_viewport_region() -> void:
    _update_viewport_region_helper()
    
    # TODO: This hack seems to be needed in order for the viewport to actually
    #       update its dimensions correctly.
    Time.set_timeout(funcref(self, "_update_viewport_region_helper"), 1.0)

func _update_viewport_region_helper() -> void:
    var game_area_region: Rect2 = ScaffoldUtils.get_game_area_region()
    var viewport_size := get_viewport().size
    var game_area_position := (viewport_size - game_area_region.size) * 0.5
    
    $PanelContainer.rect_size = viewport_size
    $PanelContainer/ViewportContainer.rect_position = game_area_position
    $PanelContainer/ViewportContainer/Viewport.size = \
            game_area_region.size
    
    call_deferred("_fix_viewport_dimensions_hack")
    Time.set_timeout(funcref(self, "_fix_viewport_dimensions_hack"), 0.4)

func _fix_viewport_dimensions_hack() -> void:
    # TODO: This hack seems to be needed in order for the viewport to actually
    #       update its dimensions correctly.
    self.visible = false
    call_deferred("set_visible", true)

func _on_activated() -> void:
    start_level()

func start_level() -> void:
    if is_instance_valid(level):
        destroy_level()
    level = ScaffoldUtils.add_scene( \
            $PanelContainer/ViewportContainer/Viewport, \
            ScaffoldConfig.next_level_resource_path, \
            true, \
            true)
    level.start()

func destroy_level() -> void:
    assert(level != null)
    level.destroy()
    level.queue_free()
    level = null

func restart_level() -> void:
    destroy_level()
    start_level()
