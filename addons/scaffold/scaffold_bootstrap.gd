extends Node
class_name ScaffoldBootstrap

func _init() -> void:
    ScaffoldUtils.print("ScaffoldBootstrap._init")

func on_app_ready(main: Node) -> void:
    ScaffoldConfig.load_state()
    ScaffoldConfig.register_main(main)
    ScaffoldConfig.is_app_ready = true
    
    main.add_child(self)
    
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
