class_name PlayerNavigationDestinationAnnotatorControlRow
extends CheckboxControlRow


const LABEL := "P nav destination"
const DESCRIPTION := ("")


func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass


func on_pressed(pressed: bool) -> void:
    Sc.annotators.params.is_player_navigation_destination_shown = pressed
    Sc.save_state.set_setting(
            Su.PLAYER_NAVIGATION_DESTINATION_SHOWN_SETTINGS_KEY,
            pressed)


func get_is_pressed() -> bool:
    return Sc.annotators.params.is_player_navigation_destination_shown


func get_is_enabled() -> bool:
    return true
