tool
class_name PauseScreen
extends Screen

const NAME := "pause"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

var _default_item_classes := [
    LevelLabeledControlItem,
    CurrentScoreLabeledControlItem,
    HighScoreLabeledControlItem,
    TimeLabeledControlItem,
]

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
    $FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/LabeledControlList \
            .items = _get_items()
    _give_button_focus($FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/VBoxContainer/ \
            ResumeButton)

func _get_items() -> Array:
    var item_classes := \
            Gs.utils.get_collection_from_exclusions_and_inclusions( \
                    _default_item_classes, \
                    Gs.pause_item_class_exclusions, \
                    Gs.pause_item_class_inclusions)
    var items := []
    for item_class in item_classes:
        items.push_back(item_class.new(Gs.level))
    return items

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer/ResumeButton as \
            ShinyButton

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
