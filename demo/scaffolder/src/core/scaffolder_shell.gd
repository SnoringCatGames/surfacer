@icon("res://icons/ScaffolderNode.svg")
class_name ScaffolderShell
extends Container


const HUD_SCENE := preload("res://scaffolder/src/ui/hud/hud.tscn")

var _canvas_layers: Dictionary[String, CanvasLayer]


func _init() -> void:
    S.log.on_global_init(self, "ScaffolderShell")


func _enter_tree() -> void:
    _create_canvas_layers()

    if (not S.utils.is_running_in_isolated_scene_mode()
            or get_tree().get_current_scene() is ScaffolderLevel):
        var hud := HUD_SCENE.instantiate()
        add_to_canvas_layer("hud", hud)


func _ready() -> void:
    if S.log.logs_early_bootstrap_events:
        S.log.print("ScaffolderShell._ready")

    S.shell = self

    await get_tree().process_frame

    S.screens.open(S.manifest.initial_screen)


func _notification(notification: int) -> void:
    match notification:
        NOTIFICATION_WM_GO_BACK_REQUEST:
            # Handle the Android back button to navigate within the app instead of
            # quitting the app.
            if S.screens.is_top_screen("main_menu"):
                close_app()
            else:
                # TODO: Close the current screen if it's not game_screen.
                pass
        NOTIFICATION_WM_CLOSE_REQUEST:
            close_app()
        NOTIFICATION_WM_WINDOW_FOCUS_OUT:
            if is_instance_valid(S.level) and S.manifest.pauses_on_focus_out:
                S.level.pause()
        _:
            pass


func _unhandled_input(event: InputEvent) -> void:
    if S.manifest.dev_mode:
        if event is InputEventKey:
            match event.physical_keycode:
                KEY_P:
                    S.utils.take_screenshot()
                KEY_O:
                    if is_instance_valid(S.hud):
                        S.hud.visible = not S.hud.visible
                        S.log.print(
                            "Toggled HUD visibility: %s" %
                            ("visible" if S.hud.visible else "hidden"))
                KEY_ESCAPE:
                    if is_instance_valid(S.level):
                        S.level.pause()
                _:
                    pass


func close_app() -> void:
    if S.utils.were_screenshots_taken:
        S.utils.open_screenshot_folder()
    S.log.print("Shell.close_app")
    get_tree().call_deferred("quit")


func _create_canvas_layers() -> void:
    var layer_count := S.manifest.canvas_layers.size()
    for index in range(layer_count):
        var config := S.manifest.canvas_layers[index]
        var z_index := layer_count - index
        var canvas_layer := CanvasLayer.new()
        canvas_layer.name = config.name
        canvas_layer.process_mode = config.process_mode
        canvas_layer.layer = z_index
        add_child(canvas_layer)
        _canvas_layers[config.name] = canvas_layer


func add_to_canvas_layer(layer_name: String, node: Node) -> void:
    if not S.utils.ensure(
            _canvas_layers.has(layer_name),
            "ScaffolderShell.add_to_canvas_layer: Invalid CanvasLayer name: %s" %
                layer_name):
        return
    _canvas_layers[layer_name].add_child(node)


func remove_from_canvas_layer(layer_name: String, node: Node) -> void:
    if not S.utils.ensure(
            _canvas_layers.has(layer_name),
            "ScaffolderShell.remove_from_canvas_layer: Invalid CanvasLayer name: %s" %
                layer_name):
        return
    _canvas_layers[layer_name].remove_child(node)
