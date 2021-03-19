tool
extends Screen
class_name SettingsScreen

const NAME := "settings"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := true
const INCLUDES_CENTER_CONTAINER := true

const _DEFAULT_MAIN_ITEMS := [
    {
        label = "Music",
        type = LabeledControlItemType.CHECKBOX,
    },
    {
        label = "Sound effects",
        type = LabeledControlItemType.CHECKBOX,
    },
    {
        label = "Haptic feedback",
        type = LabeledControlItemType.CHECKBOX,
    },
]

const _DEFAULT_DETAILS_ITEMS := [
    {
        label = "Debug time display",
        type = LabeledControlItemType.CHECKBOX,
    },
    {
        label = "Debug panel",
        type = LabeledControlItemType.CHECKBOX,
    },
]

var main_items: Array
var details_items: Array

var _main_list: LabeledControlList
var _details_list: LabeledControlList

func _init().( \
        NAME, \
        LAYER_NAME, \
        AUTO_ADAPTS_GUI_SCALE, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    main_items = _DEFAULT_MAIN_ITEMS.duplicate()
    details_items = _DEFAULT_DETAILS_ITEMS.duplicate()

func _ready() -> void:
    _main_list = $FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/MainList
    _details_list = $FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/AccordionPanel/ \
            VBoxContainer/DetailsList
    _main_list.connect( \
            "control_changed", \
            self, \
            "_on_control_changed", \
            [true])
    _details_list.connect( \
            "control_changed", \
            self, \
            "_on_control_changed", \
            [false])
    _main_list.items = main_items
    _details_list.items = details_items

func _on_activated() -> void:
    ._on_activated()
    _initialize_selections()
    _initialize_enablement()
    _main_list.items = main_items
    _details_list.items = details_items

func _initialize_selections() -> void:
    _main_list.find_item("Haptic feedback").pressed = \
            ScaffoldConfig.is_giving_haptic_feedback
    _details_list.find_item("Debug panel").pressed = \
            ScaffoldConfig.is_debug_panel_shown
    
    _details_list.find_item("Debug time display").pressed = \
            ScaffoldConfig.is_debug_time_shown
    
    _main_list.find_item("Music").pressed = \
            Audio.is_music_enabled
    _main_list.find_item("Sound effects").pressed = \
            Audio.is_sound_effects_enabled

func _initialize_enablement() -> void:
    _main_list.find_item("Haptic feedback").disabled = \
            !ScaffoldUtils.get_is_mobile_device()
    
    _details_list.find_item("Debug panel").disabled = false 
    _details_list.find_item("Debug time display").disabled = false 
    _main_list.find_item("Music").disabled = false 
    _main_list.find_item("Sound effects").disabled = false 

func _on_control_changed( \
        index: int, \
        is_main: bool) -> void:
    var item: Dictionary = \
            main_items[index] if \
            is_main else \
            details_items[index]
    
    match item.label:
        "Haptic feedback":
            _on_haptic_feedback_pressed(item.pressed)
        "Debug panel":
            _on_debug_panel_pressed(item.pressed)
        "Debug time display":
            _on_debug_time_display_pressed(item.pressed)
        "Music":
            _on_music_pressed(item.pressed)
        "Sound effects":
            _on_sound_effects_pressed(item.pressed)
        _:
            ScaffoldUtils.error()

func _on_haptic_feedback_pressed(pressed: bool) -> void:
    ScaffoldConfig.is_giving_haptic_feedback = pressed
    SaveState.set_setting( \
            ScaffoldConfig.IS_GIVING_HAPTIC_FEEDBACK_SETTINGS_KEY, \
            ScaffoldConfig.is_giving_haptic_feedback)

func _on_debug_panel_pressed(pressed: bool) -> void:
    ScaffoldConfig.is_debug_panel_shown = pressed
    SaveState.set_setting( \
            ScaffoldConfig.IS_DEBUG_PANEL_SHOWN_SETTINGS_KEY, \
            ScaffoldConfig.is_debug_panel_shown)

func _on_debug_time_display_pressed(pressed: bool) -> void:
    ScaffoldConfig.is_debug_time_shown = pressed
    SaveState.set_setting( \
            ScaffoldConfig.IS_DEBUG_TIME_SHOWN_SETTINGS_KEY, \
            ScaffoldConfig.is_debug_time_shown)
    # FIXME: -------------------

func _on_music_pressed(pressed: bool):
    Audio.is_music_enabled = pressed
    SaveState.set_setting( \
            ScaffoldConfig.IS_MUSIC_ENABLED_SETTINGS_KEY, \
            Audio.is_music_enabled)

func _on_sound_effects_pressed(pressed: bool):
    Audio.is_sound_effects_enabled = pressed
    SaveState.set_setting( \
            ScaffoldConfig.IS_SOUND_EFFECTS_ENABLED_SETTINGS_KEY, \
            Audio.is_sound_effects_enabled)
