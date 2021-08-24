class_name NpcNonSlowMoTrajectoryAnnotatorControlRow
extends CheckboxControlRow


const LABEL := "NPC act traj"
const DESCRIPTION := ("")


func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass


func on_pressed(pressed: bool) -> void:
    Su.ann_manifest.is_npc_non_slow_mo_trajectory_shown = pressed
    Sc.save_state.set_setting(
            Su.NPC_NON_SLOW_MO_TRAJECTORY_SHOWN_SETTINGS_KEY,
            pressed)


func get_is_pressed() -> bool:
    return Su.ann_manifest.is_npc_non_slow_mo_trajectory_shown


func get_is_enabled() -> bool:
    return true
