class_name ScaffoldStyles
extends Node

var button_corner_radius: int
var button_corner_detail: int
var button_shadow_size: int

var dropdown_corner_radius: int
var dropdown_corner_detail: int

var scroll_corner_radius: int
var scroll_corner_detail: int
# Width of the scrollbar.
var scroll_content_margin: int

var scroll_grabber_corner_radius: int
var scroll_grabber_corner_detail: int

func register_styles(manifest: Dictionary) -> void:
    self.button_corner_radius = manifest.button_corner_radius
    self.button_corner_detail = manifest.button_corner_detail
    self.button_shadow_size = manifest.button_shadow_size
    
    self.dropdown_corner_radius = manifest.dropdown_corner_radius
    self.dropdown_corner_detail = manifest.dropdown_corner_detail
    
    self.scroll_corner_radius = manifest.scroll_corner_radius
    self.scroll_corner_detail = manifest.scroll_corner_detail
    self.scroll_content_margin = manifest.scroll_content_margin
    
    self.scroll_grabber_corner_radius = manifest.scroll_grabber_corner_radius
    self.scroll_grabber_corner_detail = manifest.scroll_grabber_corner_detail

func configure_theme() -> void:
    _configure_theme_color( \
            "font_color", "Label", Gs.colors.font_color)
    _configure_theme_color( \
            "font_color", "Button", Gs.colors.font_color)
    _configure_theme_color( \
            "font_color", "CheckBox", Gs.colors.font_color)
    _configure_theme_color( \
            "font_color", "ItemList", Gs.colors.font_color)
    _configure_theme_color( \
            "font_color", "OptionButton", Gs.colors.font_color)
    _configure_theme_color( \
            "font_color", "PopupMenu", Gs.colors.font_color)
    _configure_theme_color( \
            "font_color", "Tree", Gs.colors.font_color)
    
    _configure_theme_stylebox( \
            "disabled", "Button", {
                bg_color = Gs.colors.button_disabled_color,
                corner_radius = Gs.styles.button_corner_radius,
                corner_detail = Gs.styles.button_corner_detail,
                shadow_size = round(Gs.styles.button_shadow_size * 0.0),
            })
    _configure_theme_stylebox( \
            "focused", "Button", {
                bg_color = Gs.colors.button_focused_color,
                corner_radius = Gs.styles.button_corner_radius,
                corner_detail = Gs.styles.button_corner_detail,
                shadow_size = round(Gs.styles.button_shadow_size * 1.5),
                shadow_color = Color.from_hsv(0, 0, 0, 0.5),
            })
    _configure_theme_stylebox( \
            "hover", "Button", {
                bg_color = Gs.colors.button_hover_color,
                corner_radius = Gs.styles.button_corner_radius,
                corner_detail = Gs.styles.button_corner_detail,
                shadow_size = round(Gs.styles.button_shadow_size * 1.5),
                shadow_color = Color.from_hsv(0, 0, 0, 0.5),
            })
    _configure_theme_stylebox( \
            "normal", "Button", {
                bg_color = Gs.colors.button_normal_color,
                corner_radius = Gs.styles.button_corner_radius,
                corner_detail = Gs.styles.button_corner_detail,
                shadow_size = Gs.styles.button_shadow_size,
            })
    _configure_theme_stylebox( \
            "pressed", "Button", {
                bg_color = Gs.colors.button_pressed_color,
                corner_radius = Gs.styles.button_corner_radius,
                corner_detail = Gs.styles.button_corner_detail,
                shadow_size = round(Gs.styles.button_shadow_size * 0.2),
            })
    
    _configure_theme_stylebox( \
            "disabled", "OptionButton", {
                bg_color = Gs.colors.dropdown_disabled_color,
                corner_radius = Gs.styles.dropdown_corner_radius,
                corner_detail = Gs.styles.dropdown_corner_detail,
            })
    _configure_theme_stylebox( \
            "focused", "OptionButton", {
                bg_color = Gs.colors.dropdown_focused_color,
                corner_radius = Gs.styles.dropdown_corner_radius,
                corner_detail = Gs.styles.dropdown_corner_detail,
            })
    _configure_theme_stylebox( \
            "hover", "OptionButton", {
                bg_color = Gs.colors.dropdown_hover_color,
                corner_radius = Gs.styles.dropdown_corner_radius,
                corner_detail = Gs.styles.dropdown_corner_detail,
            })
    _configure_theme_stylebox( \
            "normal", "OptionButton", {
                bg_color = Gs.colors.dropdown_normal_color,
                corner_radius = Gs.styles.dropdown_corner_radius,
                corner_detail = Gs.styles.dropdown_corner_detail,
            })
    _configure_theme_stylebox( \
            "pressed", "OptionButton", {
                bg_color = Gs.colors.dropdown_pressed_color,
                corner_radius = Gs.styles.dropdown_corner_radius,
                corner_detail = Gs.styles.dropdown_corner_detail,
            })
    
    _configure_theme_stylebox( \
            "panel", "PopupMenu", Gs.colors.popup_background_color)
    
    _configure_theme_stylebox( \
            "scroll", "HScrollBar", {
                bg_color = Gs.colors.scroll_bar_background_color,
                corner_radius = Gs.styles.scroll_corner_radius,
                corner_detail = Gs.styles.scroll_corner_detail,
                content_margin = Gs.styles.scroll_content_margin,
            })
    _configure_theme_stylebox( \
            "grabber", "HScrollBar", {
                bg_color = Gs.colors.scroll_bar_grabber_normal_color,
                corner_radius = Gs.styles.scroll_grabber_corner_radius,
                corner_detail = Gs.styles.scroll_grabber_corner_detail,
            })
    _configure_theme_stylebox( \
            "grabber_highlight", "HScrollBar", {
                bg_color = Gs.colors.scroll_bar_grabber_hover_color,
                corner_radius = Gs.styles.scroll_grabber_corner_radius,
                corner_detail = Gs.styles.scroll_grabber_corner_detail,
            })
    _configure_theme_stylebox( \
            "grabber_pressed", "HScrollBar", {
                bg_color = Gs.colors.scroll_bar_grabber_pressed_color,
                corner_radius = Gs.styles.scroll_grabber_corner_radius,
                corner_detail = Gs.styles.scroll_grabber_corner_detail,
            })
    
    _configure_theme_stylebox( \
            "scroll", "VScrollBar", {
                bg_color = Gs.colors.scroll_bar_background_color,
                corner_radius = Gs.styles.scroll_corner_radius,
                corner_detail = Gs.styles.scroll_corner_detail,
                content_margin = Gs.styles.scroll_content_margin,
            })
    _configure_theme_stylebox( \
            "grabber", "VScrollBar", {
                bg_color = Gs.colors.scroll_bar_grabber_normal_color,
                corner_radius = Gs.styles.scroll_grabber_corner_radius,
                corner_detail = Gs.styles.scroll_grabber_corner_detail,
            })
    _configure_theme_stylebox( \
            "grabber_highlight", "VScrollBar", {
                bg_color = Gs.colors.scroll_bar_grabber_hover_color,
                corner_radius = Gs.styles.scroll_grabber_corner_radius,
                corner_detail = Gs.styles.scroll_grabber_corner_detail,
            })
    _configure_theme_stylebox( \
            "grabber_pressed", "VScrollBar", {
                bg_color = Gs.colors.scroll_bar_grabber_pressed_color,
                corner_radius = Gs.styles.scroll_grabber_corner_radius,
                corner_detail = Gs.styles.scroll_grabber_corner_detail,
            })
    
    _configure_theme_stylebox( \
            "panel", "Panel", Gs.colors.background_color)
    _configure_theme_stylebox( \
            "panel", "PanelContainer", Gs.colors.background_color)
    
    _configure_theme_stylebox_empty("disabled", "CheckBox")
    _configure_theme_stylebox_empty("focus", "CheckBox")
    _configure_theme_stylebox_empty("hover", "CheckBox")
    _configure_theme_stylebox_empty("hover_pressed", "CheckBox")
    _configure_theme_stylebox_empty("normal", "CheckBox")
    _configure_theme_stylebox_empty("pressed", "CheckBox")
    
    if Gs.theme.default_font == null:
        Gs.theme.default_font = Gs.fonts.main_m

func _configure_theme_color( \
        name: String, \
        type: String, \
        color: Color) -> void:
    if !Gs.theme.has_color(name, type):
        Gs.theme.set_color(name, type, color)

func _configure_theme_stylebox( \
        name: String, \
        type: String, \
        config) -> void:
    if !Gs.theme.has_stylebox(name, type):
        var stylebox: StyleBoxFlatScalable = \
                Gs.utils.create_stylebox_flat_scalable(config)
        Gs.theme.set_stylebox(name, type, stylebox)
    elif !(Gs.theme.get_stylebox(name, type) is StyleBoxFlatScalable):
        var old: StyleBox = Gs.theme.get_stylebox(name, type)
        var new: StyleBoxFlatScalable = \
                Gs.utils.create_stylebox_flat_scalable(old)
        Gs.theme.set_stylebox(name, type, new)

func _configure_theme_stylebox_empty( \
        name: String, \
        type: String) -> void:
    if !Gs.theme.has_stylebox(name, type):
        var stylebox := StyleBoxEmpty.new()
        Gs.theme.set_stylebox(name, type, stylebox)
