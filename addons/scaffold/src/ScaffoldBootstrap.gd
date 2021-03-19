extends Node
class_name ScaffoldBootstrap

func _init() -> void:
    ScaffoldUtils.print("ScaffoldBootstrap._init")
    name = "ScaffoldBootstrap"

func on_app_ready( \
        app_manifest: Dictionary, \
        main: Node) -> void:
    ScaffoldConfig.register_app_manifest(app_manifest)
    ScaffoldConfig.load_state()
    
    main.add_child(self)
    
    ScaffoldConfig.camera_controller = CameraController.new()
    main.add_child(ScaffoldConfig.camera_controller)
    
    ScaffoldConfig.canvas_layers = CanvasLayers.new()
    main.add_child(ScaffoldConfig.canvas_layers)
    
    ScaffoldConfig.debug_panel = ScaffoldUtils.add_scene( \
            ScaffoldConfig.canvas_layers.layers.top, \
            ScaffoldConfig.DEBUG_PANEL_RESOURCE_PATH, \
            true, \
            true)
    ScaffoldConfig.debug_panel.z_index = 1000
    ScaffoldConfig.debug_panel.visible = ScaffoldConfig.is_debug_panel_shown
    
    if ScaffoldConfig.debug or ScaffoldConfig.playtest:
        ScaffoldConfig.gesture_record = GestureRecord.new()
        ScaffoldConfig.canvas_layers.layers.top \
                .add_child(ScaffoldConfig.gesture_record)
    
    ScaffoldConfig.is_app_ready = true
    
    _set_window_debug_size_and_position()
    
    get_tree().root.set_pause_mode(Node.PAUSE_MODE_PROCESS)
    
    Nav.create_screens( \
            ScaffoldConfig.screen_exclusions, \
            ScaffoldConfig.screen_inclusions)
    
    if ScaffoldUtils.get_is_browser():
        JavaScript.eval("window.onGameReady()")
    
    Nav.splash()

func _process(_delta_sec: float) -> void:
    if ScaffoldConfig.debug or ScaffoldConfig.playtest:
        if Input.is_action_just_pressed("screenshot"):
            ScaffoldUtils.take_screenshot()

func _set_window_debug_size_and_position() -> void:
    if ScaffoldConfig.debug:
        # Useful for getting screenshots at specific resolutions.
        if ScaffoldConfig.debug_window_size == Vector2.INF:
            if OS.get_screen_count() > 1:
                # Show the game window on the other window, rather than
                # over-top the editor.
                OS.current_screen = \
                        (OS.current_screen + 1) % OS.get_screen_count()
            OS.window_fullscreen = true
            OS.window_borderless = true
        else:
            OS.window_size = ScaffoldConfig.debug_window_size
