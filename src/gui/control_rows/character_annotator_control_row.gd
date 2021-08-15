class_name CharacterAnnotatorControlRow
extends CheckboxControlRow


const LABEL := "Character sprites"
const DESCRIPTION := ""

var annotator_type := AnnotatorType.CHARACTER
var settings_key := AnnotatorType.get_settings_key(annotator_type)


func _init(__ = null).(
        LABEL,
        DESCRIPTION \
        ) -> void:
    pass


func on_pressed(pressed: bool) -> void:
    Sc.annotators.set_annotator_enabled(
            annotator_type,
            pressed)
    Sc.save_state.set_setting(
            settings_key,
            pressed)


func get_is_pressed() -> bool:
    return Sc.annotators.is_annotator_enabled(annotator_type)


func get_is_enabled() -> bool:
    return true
