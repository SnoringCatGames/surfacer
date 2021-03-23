tool
extends Screen
class_name PauseScreen

const NAME := "pause"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

# Array<Dictionary>
var list_items := [
    {
        label = "Time:",
        type = LabeledControlItemType.TEXT,
    },
]

var _control_list: LabeledControlList

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
    _control_list = $FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/LabeledControlList
    _control_list.items = list_items

func _on_activated() -> void:
    ._on_activated()
    _update_stats()
    _give_button_focus($FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/VBoxContainer/ \
            ResumeButton)

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer/ResumeButton as \
            ShinyButton

func _update_stats() -> void:
    var level: ScaffoldLevel = Gs.level
    
    _control_list.find_item("Time:").text = \
        Gs.utils.get_time_string_from_seconds( \
                Gs.time.elapsed_play_time_actual_sec - \
                level.level_start_time)
    
    _control_list.items = list_items

func _on_ExitLevelButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    Gs.nav.close_current_screen()
    Gs.level.quit()

func _on_ResumeButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    Gs.nav.close_current_screen()

func _on_RestartButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    Gs.nav.screens["game"].restart_level()
    Gs.nav.close_current_screen(true)

func _on_SendRecentGestureEventsForDebugging_pressed() -> void:
    Gs.cloud_log.record_recent_gestures()
