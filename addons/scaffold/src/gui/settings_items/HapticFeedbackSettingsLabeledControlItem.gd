extends CheckboxLabeledControlItem
class_name HapticFeedbackSettingsLabeledControlItem

const LABEL := "Haptic feedback"
const DESCRIPTION := ""

func _init().( \
        LABEL, \
        DESCRIPTION \
        ) -> void:
    pass

func on_pressed(pressed: bool) -> void:
    Gs.is_giving_haptic_feedback = pressed
    Gs.save_state.set_setting( \
            Gs.IS_GIVING_HAPTIC_FEEDBACK_SETTINGS_KEY, \
            Gs.is_giving_haptic_feedback)

func get_is_pressed() -> bool:
    return Gs.is_giving_haptic_feedback

func get_is_enabled() -> bool:
    return Gs.utils.get_is_mobile_device()
