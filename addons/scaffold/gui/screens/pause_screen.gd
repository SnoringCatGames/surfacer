tool
extends Screen
class_name PauseScreen

const NAME := "pause"
const LAYER_NAME := "menu_screen"
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

# Array<Dictionary>
var list_items := [
    {
        label = "Level:",
        type = LabeledControlItemType.TEXT,
    },
    {
        label = "Tier:",
        type = LabeledControlItemType.TEXT,
    },
    {
        label = "Current score:",
        type = LabeledControlItemType.TEXT,
    },
    {
        label = "High score:",
        type = LabeledControlItemType.TEXT,
    },
    {
        label = "Multiplier:",
        type = LabeledControlItemType.TEXT,
    },
    {
        label = "Speed:",
        type = LabeledControlItemType.TEXT,
    },
    {
        label = "Difficulty:",
        type = LabeledControlItemType.TEXT,
    },
    {
        label = "Lives:",
        type = LabeledControlItemType.TEXT,
    },
    {
        label = "Time:",
        type = LabeledControlItemType.TEXT,
    },
]

var _control_list: LabeledControlList

func _init().( \
        NAME, \
        LAYER_NAME, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    pass

func _ready() -> void:
    _control_list = $FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/LabeledControlList
    _control_list.items = list_items
    
    if ScaffoldConfig.debug or ScaffoldConfig.playtest:
        $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
                CenterContainer/VBoxContainer/MoreLivesWrapper.visible = true

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
    var level: ScaffoldLevel = ScaffoldConfig.level
    
    _control_list.find_item("Time:").text = \
        ScaffoldUtils.get_time_string_from_seconds( \
                Time.elapsed_play_time_actual_sec - \
                level.level_start_time)
    
    _control_list.items = list_items

func _on_ExitLevelButton_pressed() -> void:
    ScaffoldUtils.give_button_press_feedback()
    Nav.close_current_screen()
    Analytics.event( \
            "level", \
            "quit", \
            LevelConfig.get_level_tier_version_string( \
                    Global.level.level_id, \
                    Global.level.current_tier_id), \
            Time.elapsed_play_time_actual_sec - Global.level.tier_start_time)
    Global.level.quit()

func _on_ResumeButton_pressed() -> void:
    ScaffoldUtils.give_button_press_feedback()
    Nav.close_current_screen()

func _on_RestartButton_pressed() -> void:
    ScaffoldUtils.give_button_press_feedback()
    Nav.screens["game"].restart_level()
    Nav.close_current_screen(true)

func _on_SendRecentGestureEventsForDebugging_pressed() -> void:
    Log.record_recent_gestures()
