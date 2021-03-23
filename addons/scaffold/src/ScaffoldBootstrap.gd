extends Node
class_name ScaffoldBootstrap

func _init() -> void:
    print("ScaffoldBootstrap._init")
    name = "ScaffoldBootstrap"

func on_app_ready( \
        app_manifest: Dictionary, \
        main: Node) -> void:
    Gs.register_app_manifest(app_manifest)
    Gs.load_state()
    
    main.add_child(self)
    
    Gs.camera_controller = CameraController.new()
    main.add_child(Gs.camera_controller)
    
    Gs.canvas_layers = CanvasLayers.new()
    main.add_child(Gs.canvas_layers)
    
    Gs.debug_panel = Gs.utils.add_scene( \
            Gs.canvas_layers.layers.top, \
            Gs.DEBUG_PANEL_RESOURCE_PATH, \
            true, \
            true)
    Gs.debug_panel.z_index = 1000
    Gs.debug_panel.visible = Gs.is_debug_panel_shown
    
    if Gs.debug or Gs.playtest:
        Gs.gesture_record = GestureRecord.new()
        Gs.canvas_layers.layers.top \
                .add_child(Gs.gesture_record)
    
    Gs.is_app_ready = true
    
    _set_window_debug_size_and_position()
    
    get_tree().root.set_pause_mode(Node.PAUSE_MODE_PROCESS)
    
    Gs.nav.create_screens( \
            Gs.screen_exclusions, \
            Gs.screen_inclusions)
    
    if Gs.utils.get_is_browser():
        JavaScript.eval("window.onGameReady()")
    
    Gs.nav.splash()
    
    Gs.utils.connect( \
            "display_resized", \
            self, \
            "_on_resized")
    _on_resized()

func _process(_delta_sec: float) -> void:
    if Gs.debug or Gs.playtest:
        if Input.is_action_just_pressed("screenshot"):
            Gs.utils.take_screenshot()

func _on_resized() -> void:
    for key in Gs.fonts:
        Gs.fonts[key].size = \
                Gs.original_font_sizes[key] * \
                Gs.gui_scale

func _set_window_debug_size_and_position() -> void:
    if Gs.debug:
        # Useful for getting screenshots at specific resolutions.
        if Gs.debug_window_size == Vector2.INF:
            if OS.get_screen_count() > 1:
                # Show the game window on the other window, rather than
                # over-top the editor.
                OS.current_screen = \
                        (OS.current_screen + 1) % OS.get_screen_count()
            OS.window_fullscreen = true
            OS.window_borderless = true
        else:
            OS.window_size = Gs.debug_window_size
