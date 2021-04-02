class_name PlayerTrajectoryAnnotatorSettingsLabeledControlItem
extends CheckboxLabeledControlItem

const LABEL := "Player trajectories"
const DESCRIPTION := ""

var annotator_type := AnnotatorType.PLAYER_TRAJECTORY
var settings_key := AnnotatorType.get_settings_key(annotator_type)

func _init(__ = null).( \
        LABEL, \
        DESCRIPTION \
        ) -> void:
    pass

func on_pressed(pressed: bool) -> void:
    Surfacer.annotators.set_annotator_enabled( \
            annotator_type, \
            pressed)
    Gs.save_state.set_setting( \
            settings_key, \
            pressed)

func get_is_pressed() -> bool:
    return Surfacer.annotators.is_annotator_enabled(annotator_type)

func get_is_enabled() -> bool:
    return true
