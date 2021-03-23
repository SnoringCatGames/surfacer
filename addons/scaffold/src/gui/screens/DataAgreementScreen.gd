extends Screen
class_name DataAgreementScreen

const NAME := "data_agreement"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

func _init().( \
        NAME, \
        LAYER_NAME, \
        AUTO_ADAPTS_GUI_SCALE, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    pass

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/AgreeButton as ShinyButton

func _on_PrivacyPolicyLink_pressed():
    Gs.utils.give_button_press_feedback()
    OS.shell_open(Gs.privacy_policy_url)

func _on_TermsAndConditionsLink_pressed():
    Gs.utils.give_button_press_feedback()
    OS.shell_open(Gs.terms_and_conditions_url)

func _on_AgreeButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.set_agreed_to_terms()
    Gs.nav.open("main_menu")
