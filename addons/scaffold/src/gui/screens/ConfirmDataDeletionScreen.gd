extends Screen
class_name ConfirmDataDeletionScreen

const NAME := "confirm_data_deletion"
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

func _ready() -> void:
    $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/ClientIdNumber.text = \
            str(Gs.analytics.client_id)

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/CancelButton as ShinyButton

func _on_ConfirmButton_pressed():
    Gs.utils.give_button_press_feedback()
    
    Gs.save_state.erase_all_state()
    
    # Erase user files.
    Gs.utils.clear_directory("user://")
    
    var url := Gs.utils.get_support_url()
    url += "&request-data-deletion=true&client-id=" + str(Gs.analytics.client_id)
    OS.shell_open(url)
    
    quit()

func quit() -> void:
    get_tree().quit()
    Gs.nav.open("data_agreement")

func _on_CancelButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.nav.close_current_screen()
