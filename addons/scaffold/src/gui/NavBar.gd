tool
class_name NavBar, "res://addons/scaffold/assets/images/editor_icons/NavBar.png"
extends PanelContainer

export var text := "" setget _set_text
export var shows_back := true setget _set_shows_back,_get_shows_back
export var shows_about := false setget _set_shows_about,_get_shows_about
export var shows_settings := false setget \
        _set_shows_settings,_get_shows_settings
export var shows_logo := false setget _set_shows_logo,_get_shows_logo

func _enter_tree() -> void:
    # FIXME: -------- CReate a utils method to do this; but actually remove the style override here;
    var style_updated := StyleBoxFlat.new()
    style_updated.bg_color = Gs.colors.background_color
    add_stylebox_override("panel", style_updated)
    
    $MarginContainer/Header.add_color_override( \
            "font_color", Gs.colors.header_font_color)
    
    $MarginContainer.set( \
            "custom_constants/margin_top", \
            Gs.utils.get_safe_area_margin_top())
    $MarginContainer/BackButton.rect_position.x += \
            Gs.utils.get_safe_area_margin_left()
    $MarginContainer/AboutButton.rect_position.x += \
            Gs.utils.get_safe_area_margin_left()
    $MarginContainer/SettingsButton.rect_position.x -= \
            Gs.utils.get_safe_area_margin_right()
    _set_shows_back(shows_back)
    _set_shows_about(shows_about)
    _set_shows_settings(shows_settings)
    _set_shows_logo(shows_logo)
    $MarginContainer/LogoWrapper/Logo.texture = Gs.app_logo
    $MarginContainer/LogoWrapper/Logo.texture_scale = \
            Vector2(Gs.app_logo_scale, Gs.app_logo_scale)

func _set_text(value: String) -> void:
    text = value
    if $MarginContainer/Header != null:
        $MarginContainer/Header.text = text

func _set_shows_back(value: bool) -> void:
    shows_back = value
    if $MarginContainer/BackButton != null:
        $MarginContainer/BackButton.visible = shows_back

func _get_shows_back() -> bool:
    return shows_back

func _set_shows_about(value: bool) -> void:
    shows_about = value
    if $MarginContainer/AboutButton != null:
        $MarginContainer/AboutButton.visible = shows_about

func _get_shows_about() -> bool:
    return shows_about

func _set_shows_settings(value: bool) -> void:
    shows_settings = value
    if $MarginContainer/SettingsButton != null:
        $MarginContainer/SettingsButton.visible = shows_settings

func _get_shows_settings() -> bool:
    return shows_settings

func _set_shows_logo(value: bool) -> void:
    shows_logo = value
    if $MarginContainer/LogoWrapper != null:
        $MarginContainer/LogoWrapper.visible = shows_logo

func _get_shows_logo() -> bool:
    return shows_logo

func _on_BackButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.nav.close_current_screen()

func _on_AboutButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.nav.open("credits")

func _on_SettingsButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.nav.open("settings")
