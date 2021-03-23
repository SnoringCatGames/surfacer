extends Screen
class_name MainMenuScreen

const NAME := "main_menu"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

var projected_image: Control

func _init().( \
        NAME, \
        LAYER_NAME, \
        AUTO_ADAPTS_GUI_SCALE, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    pass

func _ready() -> void:
    if Gs.is_main_menu_image_shown:
        projected_image = Gs.utils.add_scene( \
                $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
                        CenterContainer/VBoxContainer/MainMenuImageContainer, \
                Gs.main_menu_image_scene_path, \
                true, \
                true)
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/LogoControl/Title.texture = \
            Gs.app_logo
    
    _on_resized()

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/StartGameButton as ShinyButton

func _on_resized() -> void:
    ._on_resized()
    var viewport_size := get_viewport().size
    var is_wide_enough_to_put_title_in_nav_bar := \
            viewport_size.x > Gs.app_logo.get_width() + 256
    $FullScreenPanel/VBoxContainer/NavBar.shows_logo = \
            is_wide_enough_to_put_title_in_nav_bar
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/LogoControl.visible = \
                    !is_wide_enough_to_put_title_in_nav_bar

func _on_StartGameButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    Gs.nav.open("game")
