class_name ScaffoldColors
extends Node

# --- Configured colors ---

var font_color: Color

var header_font_color: Color

var background_color: Color

var button_color: Color

var shiny_button_highlight_color: Color

var dropdown_color: Color

var button_disabled_hsv_delta: Dictionary
var button_focused_hsv_delta: Dictionary
var button_hover_hsv_delta: Dictionary
var button_pressed_hsv_delta: Dictionary

var dropdown_disabled_hsv_delta: Dictionary
var dropdown_focused_hsv_delta: Dictionary
var dropdown_hover_hsv_delta: Dictionary
var dropdown_pressed_hsv_delta: Dictionary

var popup_background_hsv_delta: Dictionary

var zebra_stripe_even_row_color_hsv_delta: Dictionary

var scroll_bar_background_hsv_delta: Dictionary
var scroll_bar_grabber_normal_hsv_delta: Dictionary
var scroll_bar_grabber_hover_hsv_delta: Dictionary
var scroll_bar_grabber_pressed_hsv_delta: Dictionary

# --- Derived colors ---

var button_normal_color: Color
var button_disabled_color: Color
var button_focused_color: Color
var button_hover_color: Color
var button_pressed_color: Color

var dropdown_normal_color: Color
var dropdown_disabled_color: Color
var dropdown_focused_color: Color
var dropdown_hover_color: Color
var dropdown_pressed_color: Color

var popup_background_color: Color

var zebra_stripe_even_row_color: Color

var scroll_bar_background_color: Color
var scroll_bar_grabber_normal_color: Color
var scroll_bar_grabber_hover_color: Color
var scroll_bar_grabber_pressed_color: Color

# ---

func register_colors(manifest: Dictionary) -> void:
    self.font_color = manifest.font_color
    self.header_font_color = manifest.header_font_color
    self.background_color = manifest.background_color
    self.button_color = manifest.button_color
    self.shiny_button_highlight_color = manifest.shiny_button_highlight_color
    self.dropdown_color = manifest.dropdown_color
    
    self.button_disabled_hsv_delta = manifest.button_disabled_hsv_delta
    self.button_focused_hsv_delta = manifest.button_focused_hsv_delta
    self.button_hover_hsv_delta = manifest.button_hover_hsv_delta
    self.button_pressed_hsv_delta = manifest.button_pressed_hsv_delta
    
    self.dropdown_disabled_hsv_delta = manifest.dropdown_disabled_hsv_delta
    self.dropdown_focused_hsv_delta = manifest.dropdown_focused_hsv_delta
    self.dropdown_hover_hsv_delta = manifest.dropdown_hover_hsv_delta
    self.dropdown_pressed_hsv_delta = manifest.dropdown_pressed_hsv_delta
    
    self.popup_background_hsv_delta = manifest.popup_background_hsv_delta
    
    self.zebra_stripe_even_row_color_hsv_delta = \
            manifest.zebra_stripe_even_row_color_hsv_delta
    
    self.scroll_bar_background_hsv_delta = \
            manifest.scroll_bar_background_hsv_delta
    self.scroll_bar_grabber_normal_hsv_delta = \
            manifest.scroll_bar_grabber_normal_hsv_delta
    self.scroll_bar_grabber_hover_hsv_delta = \
            manifest.scroll_bar_grabber_hover_hsv_delta
    self.scroll_bar_grabber_pressed_hsv_delta = \
            manifest.scroll_bar_grabber_pressed_hsv_delta
    
    _derive_colors()

func _derive_colors() -> void:
    Gs.colors.button_normal_color = Gs.colors.button_color
    Gs.colors.button_disabled_color = _derive_color_from_hsva_delta( \
            Gs.colors.button_color, Gs.colors.button_disabled_hsv_delta)
    Gs.colors.button_focused_color = _derive_color_from_hsva_delta( \
            Gs.colors.button_color, Gs.colors.button_focused_hsv_delta)
    Gs.colors.button_hover_color = _derive_color_from_hsva_delta( \
            Gs.colors.button_color, Gs.colors.button_hover_hsv_delta)
    Gs.colors.button_pressed_color = _derive_color_from_hsva_delta( \
            Gs.colors.button_color, Gs.colors.button_pressed_hsv_delta)
    
    Gs.colors.dropdown_normal_color = Gs.colors.dropdown_color
    Gs.colors.dropdown_disabled_color = _derive_color_from_hsva_delta( \
            Gs.colors.dropdown_color, Gs.colors.dropdown_disabled_hsv_delta)
    Gs.colors.dropdown_focused_color = _derive_color_from_hsva_delta( \
            Gs.colors.dropdown_color, Gs.colors.dropdown_focused_hsv_delta)
    Gs.colors.dropdown_hover_color = _derive_color_from_hsva_delta( \
            Gs.colors.dropdown_color, Gs.colors.dropdown_hover_hsv_delta)
    Gs.colors.dropdown_pressed_color = _derive_color_from_hsva_delta( \
            Gs.colors.dropdown_color, Gs.colors.dropdown_pressed_hsv_delta)
    
    Gs.colors.popup_background_color = _derive_color_from_hsva_delta( \
            Gs.colors.background_color, Gs.colors.popup_background_hsv_delta)
    
    Gs.colors.zebra_stripe_even_row_color = \
            _derive_color_from_hsva_delta( \
                    Gs.colors.background_color, \
                    Gs.colors.zebra_stripe_even_row_color_hsv_delta)
    
    Gs.colors.scroll_bar_background_color = \
            _derive_color_from_hsva_delta( \
                    Gs.colors.background_color, \
                    Gs.colors.scroll_bar_background_hsv_delta)
    Gs.colors.scroll_bar_grabber_normal_color = \
            _derive_color_from_hsva_delta( \
                    Gs.colors.button_color, \
                    Gs.colors.scroll_bar_grabber_normal_hsv_delta)
    Gs.colors.scroll_bar_grabber_hover_color = \
            _derive_color_from_hsva_delta( \
                    Gs.colors.scroll_bar_grabber_normal_color, \
                    Gs.colors.scroll_bar_grabber_hover_hsv_delta)
    Gs.colors.scroll_bar_grabber_pressed_color = \
            _derive_color_from_hsva_delta( \
                    Gs.colors.scroll_bar_grabber_normal_color, \
                    Gs.colors.scroll_bar_grabber_pressed_hsv_delta)

func _derive_color_from_hsva_delta( \
        base_color: Color, \
        delta_hsva: Dictionary) -> Color:
    return Color.from_hsv( \
            base_color.h + delta_hsva.h, \
            base_color.s + delta_hsva.s, \
            base_color.v + delta_hsva.v, \
            base_color.a + delta_hsva.a if \
                    delta_hsva.has("a") else \
                    base_color.a)
