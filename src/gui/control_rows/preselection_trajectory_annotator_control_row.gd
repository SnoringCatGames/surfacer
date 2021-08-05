class_name PreselectionTrajectoryAnnotatorControlRow
extends CheckboxControlRow


const LABEL := "Presel. trajectory"
const DESCRIPTION := ("")


func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass


func on_pressed(pressed: bool) -> void:
    Su.ann_manifest.is_preselection_trajectory_shown = pressed
    Sc.save_state.set_setting(
            Su.PRESELECTION_TRAJECTORY_SHOWN_SETTINGS_KEY,
            pressed)


func get_is_pressed() -> bool:
    return Su.ann_manifest.is_preselection_trajectory_shown


func get_is_enabled() -> bool:
    return true
