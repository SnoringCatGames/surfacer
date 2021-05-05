class_name NavigationDestinationAnnotatorSettingsLabeledControlItem
extends CheckboxLabeledControlItem

const LABEL := "Nav destination"
const DESCRIPTION := ("")

func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass

func on_pressed(pressed: bool) -> void:
    Surfacer.is_navigation_destination_shown = pressed
    Gs.save_state.set_setting(
            Surfacer.NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY,
            pressed)

func get_is_pressed() -> bool:
    return Surfacer.is_navigation_destination_shown

func get_is_enabled() -> bool:
    return true
