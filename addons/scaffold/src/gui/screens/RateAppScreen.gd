class_name RateAppScreen
extends Screen

const NAME := "rate_app"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

const NEXT_SCREEN_TYPE := "main_menu"

func _init().( \
        NAME, \
        LAYER_NAME, \
        AUTO_ADAPTS_GUI_SCALE, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    pass

func _on_activated() -> void:
    ._on_activated()
    assert(Gs.is_rate_app_shown)

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer2/RateAppButton as \
            ShinyButton

func _on_RateAppButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.save_state.set_gave_feedback(true)
    Gs.nav.open(NEXT_SCREEN_TYPE)
    var app_store_url := \
            Gs.ios_app_store_url if \
            Gs.utils.get_is_ios_device() else \
            Gs.android_app_store_url
    OS.shell_open(app_store_url)

func _on_DontAskAgainButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.save_state.set_gave_feedback(true)
    Gs.nav.open(NEXT_SCREEN_TYPE)

func _on_KeepPlayingButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.nav.open(NEXT_SCREEN_TYPE)

func _on_SendFeedbackButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    Gs.nav.open(NEXT_SCREEN_TYPE)
    OS.shell_open(Gs.utils.get_support_url())
