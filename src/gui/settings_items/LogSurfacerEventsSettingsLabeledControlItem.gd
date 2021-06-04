class_name LogSurfacerEventsSettingsLabeledControlItem
extends CheckboxLabeledControlItem


const LABEL := "Surfacer logs"
const DESCRIPTION := (
        "This toggles whether log are printed for Surfacer events. " +
        "These events can be helpful for debugging, and normal users " +
        "won't care. " +
        "These logs would be shown in the debug panel.")


func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass


func on_pressed(pressed: bool) -> void:
    Surfacer.is_surfacer_logging = pressed
    Gs.save_state.set_setting(
            Surfacer.IS_SURFACER_LOGGING_SETTINGS_KEY,
            pressed)


func get_is_pressed() -> bool:
    return Surfacer.is_surfacer_logging


func get_is_enabled() -> bool:
    return true
