tool
extends Screen
class_name SettingsScreen

const NAME := "settings"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

var _default_main_items := [
    MusicSettingsLabeledControlItem.new(),
    SoundEffectsSettingsLabeledControlItem.new(),
    HapticFeedbackSettingsLabeledControlItem.new(),
]

var _default_details_items := [
    DebugPanelSettingsLabeledControlItem.new(),
]

var main_items: Array
var details_items: Array

func _init().( \
        NAME, \
        LAYER_NAME, \
        AUTO_ADAPTS_GUI_SCALE, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    main_items = _default_main_items.duplicate()
    details_items = _default_details_items.duplicate()

func _on_activated() -> void:
    ._on_activated()
    $FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/MainList.items = \
            main_items
    $FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/AccordionPanel/ \
            VBoxContainer/DetailsList.items = details_items
