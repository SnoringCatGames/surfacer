class_name Screen
extends Node2D

var screen_name: String
var layer_name: String
var auto_adapts_gui_scale: bool
var includes_standard_hierarchy: bool
var includes_nav_bar: bool
var includes_center_container: bool

var default_gui_scale := 1.0

var outer_panel_container: PanelContainer
var nav_bar: Control
var scroll_container: ScrollContainer
var inner_vbox: VBoxContainer
var stylebox: StyleBoxFlatScalable

var _focused_button: ShinyButton

var params: Dictionary

func _init( \
        screen_name: String, \
        layer_name: String, \
        auto_adapts_gui_scale: bool, \
        includes_standard_hierarchy: bool, \
        includes_nav_bar := true, \
        includes_center_container := true) -> void:
    self.screen_name = screen_name
    self.layer_name = layer_name
    self.auto_adapts_gui_scale = auto_adapts_gui_scale
    self.includes_standard_hierarchy = includes_standard_hierarchy
    self.includes_nav_bar = includes_nav_bar
    self.includes_center_container = includes_center_container

func _ready() -> void:
    _validate_node_hierarchy()
    Gs.utils.connect( \
            "display_resized", \
            self, \
            "_on_resized")
    _on_resized()

func _exit_tree() -> void:
    if is_instance_valid(stylebox):
        stylebox.destroy()

func _validate_node_hierarchy() -> void:
    # Give a shadow to the outer-most panel.
    outer_panel_container = get_child(0)
    assert(outer_panel_container is PanelContainer)
    outer_panel_container.theme = Gs.theme
    stylebox = Gs.utils.create_stylebox_flat_scalable({
        bg_color = Gs.colors.background_color,
        shadow_size = 8,
        shadow_offset = Vector2(-4.0, 4.0),
    })
    outer_panel_container.add_stylebox_override("panel", stylebox)
    
    if auto_adapts_gui_scale:
        Gs.add_gui_to_scale( \
                outer_panel_container, \
                default_gui_scale)
    
    if includes_standard_hierarchy:
        var outer_vbox: VBoxContainer = $FullScreenPanel/VBoxContainer
        outer_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        outer_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
        
        if includes_nav_bar:
            nav_bar = $FullScreenPanel/VBoxContainer/NavBar
        
        scroll_container = \
                $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer
        assert(scroll_container != null)
        scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
        
        if includes_center_container:
            inner_vbox = $FullScreenPanel/VBoxContainer/CenteredPanel/ \
                    ScrollContainer/CenterContainer/VBoxContainer
            assert(inner_vbox != null)
            
            var center_container: CenterContainer = \
                    $FullScreenPanel/VBoxContainer/CenteredPanel/ \
                    ScrollContainer/CenterContainer
            center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
        else:
            inner_vbox = $FullScreenPanel/VBoxContainer/CenteredPanel/ \
                    ScrollContainer/VBoxContainer
            assert(inner_vbox != null)
        
        Gs.utils.set_mouse_filter_recursively( \
                scroll_container, \
                Control.MOUSE_FILTER_PASS)

func _unhandled_key_input(event: InputEventKey) -> void:
    if (event.scancode == KEY_SPACE or \
            event.scancode == KEY_ENTER) and \
            event.pressed and \
            _focused_button != null and \
            Gs.nav.get_active_screen() == self:
        _focused_button.press()
    elif (event.scancode == KEY_ESCAPE) and \
            event.pressed and \
            nav_bar != null and \
            nav_bar.shows_back and \
            Gs.nav.get_active_screen() == self:
        Gs.nav.close_current_screen()

func _on_activated() -> void:
    _give_button_focus(_get_focused_button())
    if includes_standard_hierarchy:
        Gs.utils.set_mouse_filter_recursively( \
                scroll_container, \
                Control.MOUSE_FILTER_PASS)

func _on_deactivated() -> void:
    pass

func _on_resized() -> void:
    pass

func _get_focused_button() -> ShinyButton:
    return null

func _scroll_to_top() -> void:
    if includes_standard_hierarchy:
        yield(get_tree(), "idle_frame")
        var scroll_bar := scroll_container.get_v_scrollbar()
        scroll_container.scroll_vertical = scroll_bar.min_value

func _give_button_focus(button: ShinyButton) -> void:
    if _focused_button != null:
        _focused_button.is_shiny = false
        _focused_button.includes_color_pulse = false
    _focused_button = button
    if _focused_button != null:
        _focused_button.is_shiny = true
        _focused_button.includes_color_pulse = true

func set_params(params) -> void:
    if params == null:
        return
    self.params = params
