extends CheckboxLabeledControlItem
class_name SoundEffectsSettingsLabeledControlItem

const LABEL := "Sound effects"
const DESCRIPTION := ""

func _init(__ = null).( \
        LABEL, \
        DESCRIPTION \
        ) -> void:
    pass

func on_pressed(pressed: bool) -> void:
    Gs.audio.is_sound_effects_enabled = pressed
    Gs.save_state.set_setting( \
            Gs.IS_SOUND_EFFECTS_ENABLED_SETTINGS_KEY, \
            Gs.audio.is_sound_effects_enabled)

func get_is_pressed() -> bool:
    return Gs.audio.is_sound_effects_enabled

func get_is_enabled() -> bool:
    return true
