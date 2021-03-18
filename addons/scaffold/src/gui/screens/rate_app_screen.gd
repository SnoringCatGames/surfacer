extends Screen
class_name RateAppScreen

const NAME := "rate_app"
const LAYER_NAME := "menu_screen"
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

const NEXT_SCREEN_TYPE := "main_menu"

func _init().( \
        NAME, \
        LAYER_NAME, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    pass

func _on_activated() -> void:
    ._on_activated()
    assert(ScaffoldConfig.is_rate_app_shown)

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer2/RateAppButton as \
            ShinyButton

func _on_RateAppButton_pressed():
    ScaffoldUtils.give_button_press_feedback()
    SaveState.set_gave_feedback(true)
    Nav.open(NEXT_SCREEN_TYPE)
    var app_store_url := \
            ScaffoldConfig.ios_app_store_url if \
            ScaffoldUtils.get_is_ios_device() else \
            ScaffoldConfig.android_app_store_url
    OS.shell_open(app_store_url)

func _on_DontAskAgainButton_pressed():
    ScaffoldUtils.give_button_press_feedback()
    SaveState.set_gave_feedback(true)
    Nav.open(NEXT_SCREEN_TYPE)

func _on_KeepPlayingButton_pressed():
    ScaffoldUtils.give_button_press_feedback()
    Nav.open(NEXT_SCREEN_TYPE)

func _on_SendFeedbackButton_pressed() -> void:
    ScaffoldUtils.give_button_press_feedback()
    Nav.open(NEXT_SCREEN_TYPE)
    OS.shell_open(ScaffoldUtils.get_support_url())
