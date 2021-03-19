extends Node2D
class_name CanvasLayers

const _DEFAULT_LAYERS_CONFIG := [
    {
        name = "menu_screen",
        z_index = 40,
        pause_mode = Node.PAUSE_MODE_PROCESS,
    },
    {
        name = "top",
        z_index = 50,
        pause_mode = Node.PAUSE_MODE_PROCESS,
    },
    {
        name = "hud",
        z_index = 30,
        pause_mode = Node.PAUSE_MODE_STOP,
    },
    {
        name = "annotation",
        z_index = 20,
        pause_mode = Node.PAUSE_MODE_STOP,
    },
    {
        name = "game_screen",
        z_index = 10,
        pause_mode = Node.PAUSE_MODE_STOP,
    },
]

var layers := {}

func _init() -> void:
    ScaffoldUtils.print("CanvasLayers._init")
    name = "CanvasLayers"

func _enter_tree() -> void:
    for config in _DEFAULT_LAYERS_CONFIG:
        create_layer(config.name, config.z_index, config.pause_mode)

func create_layer( \
        name: String, \
        z_index: int, \
        pause_mode: int) -> CanvasLayer:
    var canvas_layer := CanvasLayer.new()
    canvas_layer.name = name
    canvas_layer.layer = z_index
    canvas_layer.pause_mode = pause_mode
    ScaffoldUtils.add_overlay_to_current_scene(canvas_layer)
    layers[name] = canvas_layer
    return canvas_layer
