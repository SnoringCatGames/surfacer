extends Screen
class_name MainMenuScreen

const NAME := "main_menu"
const LAYER_NAME := "menu_screen"
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

func _init().( \
        NAME, \
        LAYER_NAME, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    pass

func _ready() -> void:
    ScaffoldUtils.connect( \
            "display_resized", \
            self, \
            "_handle_display_resized")
    _handle_display_resized()

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/StartGameButton as ShinyButton

func _handle_display_resized() -> void:
    var viewport_size := get_viewport().size
    var is_wide_enough_to_put_title_in_nav_bar := viewport_size.x > 600
    $FullScreenPanel/VBoxContainer/NavBar.shows_logo = \
            is_wide_enough_to_put_title_in_nav_bar
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/LogoControl.visible = \
                    !is_wide_enough_to_put_title_in_nav_bar
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer \
            /CenterContainer/VBoxContainer/Spacer2.visible = \
                    !is_wide_enough_to_put_title_in_nav_bar
    
    var is_tall_enough_to_have_large_animation := viewport_size.y > 600
    if is_tall_enough_to_have_large_animation:
        $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/CenterContainer/VBoxContainer/Control2 \
                .rect_min_size.y = 240
        $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/CenterContainer/VBoxContainer/Control2/SlopeAnimationControl \
                .rect_scale = Vector2(4, 4)
        $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/CenterContainer/VBoxContainer/Control2/SlopeAnimationControl \
                .rect_position.y = 120
    else:
        $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/CenterContainer/VBoxContainer/Control2 \
                .rect_min_size.y = 120
        $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/CenterContainer/VBoxContainer/Control2/SlopeAnimationControl \
                .rect_scale = Vector2(2, 2)
        $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/CenterContainer/VBoxContainer/Control2/SlopeAnimationControl \
                .rect_position.y = 60

func _on_StartGameButton_pressed() -> void:
    ScaffoldUtils.give_button_press_feedback()
    Nav.open("game")
