class_name ScaffoldBootstrap
extends Node

var _throttled_size_changed: FuncRef

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
    
    Gs.nav.create_screens()
    
    if Gs.utils.get_is_browser():
        JavaScript.eval("window.onGameReady()")
    
    Gs.nav.splash()
    
    _throttled_size_changed = Gs.time.throttle( \
            funcref(self, "_on_throttled_size_changed"), \
            Gs.display_resize_throttle_interval_sec)
    get_viewport().connect( \
            "size_changed", \
            self, \
            "_on_resized")
    _on_resized()

func _process(_delta_sec: float) -> void:
    if Gs.debug or Gs.playtest:
        if Input.is_action_just_pressed("screenshot"):
            Gs.utils.take_screenshot()

func _on_resized() -> void:
    _throttled_size_changed.call_func()

func _on_throttled_size_changed() -> void:
    _update_game_area_region_and_gui_scale()
    _update_font_sizes()
    _update_checkbox_size()
    _update_tree_arrow_size()
    _scale_guis()
    Gs.utils.emit_signal("display_resized")
    # TODO: Fix the underlying dependency, instead of this double-call hack.
    #       (To repro the problem: run, maximize window, unmaximize window,
    #        Screen hasn't shrunk back to the correct size.)
    _scale_guis()
    Gs.utils.emit_signal("display_resized")

func _update_font_sizes() -> void:
    for key in Gs.fonts:
        Gs.fonts[key].size = \
                Gs.original_font_sizes[key] * \
                Gs.gui_scale

func _update_checkbox_size() -> void:
    var target_icon_size := Gs.default_checkbox_icon_size * Gs.gui_scale
    var closest_icon_size := Gs.default_checkbox_icon_size
    for icon_size in Gs.checkbox_icon_sizes:
        if abs(target_icon_size - icon_size) < \
                abs(target_icon_size - closest_icon_size):
            closest_icon_size = icon_size
    Gs.current_checkbox_icon_size = closest_icon_size
    
    var checked_icon_path := \
            Gs.checkbox_icon_path_prefix + "checked_" + \
            str(Gs.current_checkbox_icon_size) + ".png"
    var unchecked_icon_path := \
            Gs.checkbox_icon_path_prefix + "unchecked_" + \
            str(Gs.current_checkbox_icon_size) + ".png"
    
    var checked_icon := load(checked_icon_path)
    var unchecked_icon := load(unchecked_icon_path)
    
    Gs.theme.set_icon("checked", "CheckBox", checked_icon)
    Gs.theme.set_icon("unchecked", "CheckBox", unchecked_icon)

func _update_tree_arrow_size() -> void:
    var target_icon_size := Gs.default_tree_arrow_icon_size * Gs.gui_scale
    var closest_icon_size := Gs.default_tree_arrow_icon_size
    for icon_size in Gs.tree_arrow_icon_sizes:
        if abs(target_icon_size - icon_size) < \
                abs(target_icon_size - closest_icon_size):
            closest_icon_size = icon_size
    Gs.current_tree_arrow_icon_size = closest_icon_size
    
    var open_icon_path := \
            Gs.tree_arrow_icon_path_prefix + "open_" + \
            str(Gs.current_tree_arrow_icon_size) + ".png"
    var closed_icon_path := \
            Gs.tree_arrow_icon_path_prefix + "closed_" + \
            str(Gs.current_tree_arrow_icon_size) + ".png"
    
    var open_icon := load(open_icon_path)
    var closed_icon := load(closed_icon_path)
    
    Gs.theme.set_icon("arrow", "Tree", open_icon)
    Gs.theme.set_icon("arrow_collapsed", "Tree", closed_icon)
    Gs.theme.set_constant( \
            "item_margin", "Tree", Gs.current_tree_arrow_icon_size)

func _update_game_area_region_and_gui_scale() -> void:
    var viewport_size := get_viewport().size
    var aspect_ratio := viewport_size.x / viewport_size.y
    var game_area_position := Vector2.INF
    var game_area_size := Vector2.INF
    
    if !Gs.is_app_configured:
        game_area_size = viewport_size
        game_area_position = Vector2.ZERO
    if aspect_ratio < Gs.aspect_ratio_min:
        # Show vertical margin around game area.
        game_area_size = Vector2( \
                viewport_size.x, \
                viewport_size.x / Gs.aspect_ratio_min)
        game_area_position = Vector2( \
                0.0, \
                (viewport_size.y - game_area_size.y) * 0.5)
    elif aspect_ratio > Gs.aspect_ratio_max:
        # Show horizontal margin around game area.
        game_area_size = Vector2( \
                viewport_size.y * Gs.aspect_ratio_max, \
                viewport_size.y)
        game_area_position = Vector2( \
                (viewport_size.x - game_area_size.x) * 0.5, \
                0.0)
    else:
        # Show no margins around game area.
        game_area_size = viewport_size
        game_area_position = Vector2.ZERO
    
    Gs.game_area_region = Rect2(game_area_position, game_area_size)
    
    if Gs.is_app_configured:
        var default_aspect_ratio: float = \
                Gs.default_game_area_size.x / \
                Gs.default_game_area_size.y
        Gs.gui_scale = \
                viewport_size.x / Gs.default_game_area_size.x if \
                aspect_ratio < default_aspect_ratio else \
                viewport_size.y / Gs.default_game_area_size.y
        Gs.gui_scale = \
                max(Gs.gui_scale, Gs.MIN_GUI_SCALE)

func _scale_guis() -> void:
    for gui in Gs.guis_to_scale:
        Gs.utils._scale_gui_for_current_screen_size(gui)

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
