extends Screen
class_name DataAgreementScreen

const NAME := "data_agreement"
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
    # FIXME: ------------------------
    # - conditionally show/hide urls based on whether pp and tos are configured;
    # - conditionally show this screen based on the same;
    # - Also, conditionally show the data-deletion screen link, and corresponding urls in credits screen;
    # - Also, dynamically update credits screen text based on urls?
    pass

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/AgreeButton as ShinyButton

func _on_PrivacyPolicyLink_pressed():
    ScaffoldUtils.give_button_press_feedback()
    OS.shell_open(ScaffoldConfig.privacy_policy_url)

func _on_TermsAndConditionsLink_pressed():
    ScaffoldUtils.give_button_press_feedback()
    OS.shell_open(ScaffoldConfig.terms_and_conditions_url)

func _on_AgreeButton_pressed():
    ScaffoldUtils.give_button_press_feedback()
    ScaffoldConfig.set_agreed_to_terms()
    Nav.open("main_menu")
