class_name InspectorEnabledControlRow
extends CheckboxControlRow


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
    Su.is_inspector_enabled = pressed
    Sc.save_state.set_setting(
            Su.IS_INSPECTOR_ENABLED_SETTINGS_KEY,
            Su.is_inspector_enabled)


func get_is_pressed() -> bool:
    return Su.is_inspector_enabled


func get_is_enabled() -> bool:
    return true
