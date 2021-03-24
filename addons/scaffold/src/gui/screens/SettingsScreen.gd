tool
extends Screen
class_name SettingsScreen

const NAME := "settings"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

var _default_main_item_classes := [
    MusicSettingsLabeledControlItem,
    SoundEffectsSettingsLabeledControlItem,
    HapticFeedbackSettingsLabeledControlItem,
]

var _default_details_item_classes := [
    DebugPanelSettingsLabeledControlItem,
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
            ScrollContainer/CenterContainer/VBoxContainer/MainList.items = \
            _get_main_items()
    $FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/AccordionPanel/ \
            VBoxContainer/DetailsList.items = _get_details_items()

func _get_main_items() -> Array:
    var item_classes := \
            Gs.utils.get_collection_from_exclusions_and_inclusions( \
                    _default_main_item_classes, \
                    Gs.settings_main_item_class_exclusions, \
                    Gs.settings_main_item_class_inclusions)
    var items := []
    for item_class in item_classes:
        items.push_back(item_class.new())
    return items

func _get_details_items() -> Array:
    var item_classes := \
            Gs.utils.get_collection_from_exclusions_and_inclusions( \
                    _default_details_item_classes, \
                    Gs.settings_details_item_class_exclusions, \
                    Gs.settings_details_item_class_inclusions)
    var items := []
    for item_class in item_classes:
        items.push_back(item_class.new(Gs.level))
    return items
