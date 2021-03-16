extends Screen
class_name CreditsScreen

const NAME := "credits"
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

func _on_third_party_licenses_button_pressed():
    ScaffoldUtils.give_button_press_feedback()
    Nav.open("third_party_licenses")

func _on_snoring_cat_games_link_pressed():
    ScaffoldUtils.give_button_press_feedback()
    OS.shell_open(ScaffoldConfig.snoring_cat_games_url)

func _on_godot_link_pressed():
    ScaffoldUtils.give_button_press_feedback()
    OS.shell_open(ScaffoldConfig.godot_url)

func _on_PrivacyPolicyLink_pressed():
    ScaffoldUtils.give_button_press_feedback()
    OS.shell_open(ScaffoldConfig.privacy_policy_url)

func _on_TermsAndConditionsLink_pressed():
    ScaffoldUtils.give_button_press_feedback()
    OS.shell_open(ScaffoldConfig.terms_and_conditions_url)

func _on_SupportLink_pressed():
    ScaffoldUtils.give_button_press_feedback()
    OS.shell_open(ScaffoldUtils.get_support_url())

func _on_DataDeletionButton_pressed():
    ScaffoldUtils.give_button_press_feedback()
    Nav.open("confirm_data_deletion")
