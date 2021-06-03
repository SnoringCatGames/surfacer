class_name InspectorEnabledSettingsLabeledControlItem
extends CheckboxLabeledControlItem

const LABEL := "Inspector"
const DESCRIPTION := (
        "The platform-graph inspector helps to visualize and debug the " +
        "shape of the platform graph and how it was calculated.")

func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass

func on_pressed(pressed: bool) -> void:
    Surfacer.is_inspector_enabled = pressed
    Gs.save_state.set_setting(
            Surfacer.IS_INSPECTOR_ENABLED_SETTINGS_KEY,
            Surfacer.is_inspector_enabled)

func get_is_pressed() -> bool:
    return Surfacer.is_inspector_enabled

func get_is_enabled() -> bool:
    return true
