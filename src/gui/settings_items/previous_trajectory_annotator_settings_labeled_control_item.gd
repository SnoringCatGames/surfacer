class_name PreviousTrajectoryAnnotatorSettingsLabeledControlItem
extends CheckboxLabeledControlItem


const LABEL := "Prev. trajectory"
const DESCRIPTION := ("")


func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass


func on_pressed(pressed: bool) -> void:
    Su.ann_manifest.is_previous_trajectory_shown = pressed
    Sc.save_state.set_setting(
            Su.PREVIOUS_TRAJECTORY_SHOWN_SETTINGS_KEY,
            pressed)


func get_is_pressed() -> bool:
    return Su.ann_manifest.is_previous_trajectory_shown


func get_is_enabled() -> bool:
    return true
