extends CheckboxLabeledControlItem
class_name MusicSettingsLabeledControlItem

const LABEL := "Music"
const DESCRIPTION := ""

func _init().( \
        LABEL, \
        DESCRIPTION \
        ) -> void:
    pass

func on_pressed(pressed: bool) -> void:
    Gs.audio.is_music_enabled = pressed
    Gs.save_state.set_setting( \
            Gs.IS_MUSIC_ENABLED_SETTINGS_KEY, \
            Gs.audio.is_music_enabled)

func get_is_pressed() -> bool:
    return Gs.audio.is_music_enabled

func get_is_enabled() -> bool:
    return true
