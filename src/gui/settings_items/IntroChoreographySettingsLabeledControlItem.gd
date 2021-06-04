class_name IntroChoreographySettingsLabeledControlItem
extends CheckboxLabeledControlItem


const LABEL := "Intro cutscene"
const DESCRIPTION := (
        "This toggles whether some brief automatic player movement is " +
        "shown when starting a level.")


func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass


func on_pressed(pressed: bool) -> void:
    Surfacer.is_intro_choreography_shown = pressed
    Gs.save_state.set_setting(
            Surfacer.IS_INTRO_CHOREOGRAPHY_SHOWN_SETTINGS_KEY,
            pressed)


func get_is_pressed() -> bool:
    return Surfacer.is_intro_choreography_shown


func get_is_enabled() -> bool:
    return true
