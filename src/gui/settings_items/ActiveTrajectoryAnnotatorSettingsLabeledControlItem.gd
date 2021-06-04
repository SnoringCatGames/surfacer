class_name ActiveTrajectoryAnnotatorSettingsLabeledControlItem
extends CheckboxLabeledControlItem

const LABEL := "Active trajectory"
const DESCRIPTION := ("")


func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass


func on_pressed(pressed: bool) -> void:
    Surfacer.is_active_trajectory_shown = pressed
    Gs.save_state.set_setting(
            Surfacer.ACTIVE_TRAJECTORY_SHOWN_SETTINGS_KEY,
            pressed)


func get_is_pressed() -> bool:
    return Surfacer.is_active_trajectory_shown


func get_is_enabled() -> bool:
    return true
