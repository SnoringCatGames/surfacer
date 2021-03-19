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
    ScaffoldUtils.connect( \
            "display_resized", \
            self, \
            "_update_viewport_region")
    _update_viewport_region()

func _update_viewport_region() -> void:
    var game_area_region: Rect2 = ScaffoldUtils.get_game_area_region()
    var viewport_size := get_viewport().size
    $PanelContainer.rect_size = viewport_size
    $PanelContainer/ViewportContainer.rect_position = \
            (viewport_size - game_area_region.size) * 0.5
    $PanelContainer/ViewportContainer/Viewport.size = \
            game_area_region.size
    
    # TODO: This hack seems to be needed in order for the viewport to actually
    #       update its dimensions correctly.
    self.visible = false
    call_deferred("set_visible", true)

func _on_activated() -> void:
    start_level()

func start_level() -> void:
    if is_instance_valid(level):
        destroy_level()
    # FIXME: -----------------------------------
    level = ScaffoldUtils.add_scene( \
            ScaffoldConfig.canvas_layers.layers.game_screen, \
            ScaffoldConfig.next_level_resource_path, \
            true, \
            true)
#    level = ScaffoldUtils.add_scene( \
#            $PanelContainer/ViewportContainer/Viewport, \
#            ScaffoldConfig.next_level_resource_path, \
#            true, \
#            false)
    level.start()

func destroy_level() -> void:
    assert(level != null)
    level.destroy()
    level.queue_free()
    level = null

func restart_level() -> void:
    destroy_level()
    start_level()
