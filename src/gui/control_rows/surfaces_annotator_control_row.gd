class_name SurfacesAnnotatorControlRow
extends CheckboxControlRow


const LABEL := "Surfaces"
const DESCRIPTION := ""

var annotator_type := ScaffolderAnnotatorTypes.SURFACES
var settings_key := ScaffolderAnnotatorTypes.get_settings_key(annotator_type)


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
