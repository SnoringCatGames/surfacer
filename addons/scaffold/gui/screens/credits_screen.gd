extends Screen
class_name CreditsScreen

const GODOT_URL := "https://godotengine.org"

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

func _ready() -> void:
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/Control/Title.texture = \
            ScaffoldConfig.app_logo
    
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer4/ \
            DeveloperLogoLink/DeveloperLogo.visible = \
            ScaffoldConfig.is_developer_logo_shown
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer4/ \
            DeveloperLogoLink/DeveloperLogo.texture = \
            ScaffoldConfig.developer_logo
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer4/ \
            DeveloperNameLink.text = ScaffoldConfig.developer_name
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer4/ \
            DeveloperUrlLink.text = ScaffoldConfig.developer_url
    
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/SpecialThanksContainer/ \
            SpecialThanks.text = ScaffoldConfig.special_thanks_text
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/SpecialThanksContainer.visible = \
            ScaffoldConfig.is_special_thanks_shown
    
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer2/ \
            TermsAndConditionsLink.visible = ScaffoldConfig.is_data_tracked
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer2/ \
            PrivacyPolicyLink.visible = ScaffoldConfig.is_data_tracked
    
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer2/ \
            SupportLink.visible = ScaffoldConfig.is_support_shown
    
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/AccordionPanel/VBoxContainer/ \
            ThirdPartyLicensesButton.visible = \
            ScaffoldConfig.is_third_party_licenses_shown

func _on_third_party_licenses_button_pressed():
    ScaffoldUtils.give_button_press_feedback()
    Nav.open("third_party_licenses")

func _on_snoring_cat_games_link_pressed():
    ScaffoldUtils.give_button_press_feedback()
    OS.shell_open(ScaffoldConfig.developer_url)

func _on_godot_link_pressed():
    ScaffoldUtils.give_button_press_feedback()
    OS.shell_open(GODOT_URL)

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
