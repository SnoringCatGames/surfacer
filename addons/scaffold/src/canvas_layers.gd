extends Node2D
class_name CanvasLayers

const _DEFAULT_LAYERS_CONFIG := [
    {
        name = "menu_screen",
        z_index = 400,
        pause_mode = Node.PAUSE_MODE_PROCESS,
    },
    {
        name = "top",
        z_index = 500,
        pause_mode = Node.PAUSE_MODE_PROCESS,
    },
    {
        name = "hud",
        z_index = 300,
        pause_mode = Node.PAUSE_MODE_STOP,
    },
    {
        name = "annotation",
        z_index = 200,
        pause_mode = Node.PAUSE_MODE_STOP,
    },
    {
        name = "game_screen",
        z_index = 100,
        pause_mode = Node.PAUSE_MODE_STOP,
    },
]

var layers := {}

func _init() -> void:
    ScaffoldUtils.print("CanvasLayers._init")

func _enter_tree() -> void:
    for config in _DEFAULT_LAYERS_CONFIG:
        create_layer(config.name, config.z_index, config.pause_mode)

func _process(_delta_sec: float) -> void:
    # Transform the annotation layer to follow the camera.
    var camera: Camera2D = \
            ScaffoldConfig.camera_controller.get_current_camera()
    if is_instance_valid(camera):
        layers.annotation.transform = get_canvas_transform()

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
