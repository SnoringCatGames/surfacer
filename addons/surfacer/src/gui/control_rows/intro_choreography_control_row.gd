class_name IntroChoreographyControlRow
extends CheckboxControlRow


const LABEL := "Intro cutscene"
const DESCRIPTION := (
        "This toggles whether some brief automatic character movement is " +
        "shown when starting a level.")


func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass


func on_pressed(pressed: bool) -> void:
    Su.is_intro_choreography_shown = pressed
    Sc.save_state.set_setting(
            Su.IS_INTRO_CHOREOGRAPHY_SHOWN_SETTINGS_KEY,
            pressed)


func get_is_pressed() -> bool:
    return Su.is_intro_choreography_shown


func get_is_enabled() -> bool:
    return true
