class_name ScaffolderSettingsScreen
extends ScaffolderScreen


@export var checkbox_row_scene: PackedScene
@export var slider_row_scene: PackedScene

const SLIDER_WIDTH := 200


func _ready() -> void:
    super()
    for property in S.settings.get_settings_properties():
        var row := _create_row(property)
        if row:
            %SettingsRows.add_child(row)


func _create_row(property: Dictionary) -> ScaffolderSettingsRow:
    var is_numeric: bool = property.type == TYPE_INT or property.type == TYPE_FLOAT
    var is_range: bool = is_numeric and property.hint == PropertyHint.PROPERTY_HINT_RANGE

    # TODO: Remove this.
    # TODO: Add a better way to specify custom settings.
    var exclusion_list := [
        "audio_input",
        "mic_magnitude_lower_threshold",
        "mic_magnitude_upper_threshold",
        "humming_mode",
    ]
    if exclusion_list.has(property.name):
        return

    # Validate the property hint.
    if not S.utils.ensure(property.hint == PROPERTY_HINT_NONE or is_range,
            "Unsupported settings property hint: name: %s, type: %s, hint: %s" % [
                property.name, property.type, property.hint
            ]):
        return
    if not S.utils.ensure(!is_numeric or is_range,
            "Numeric settings properties must be defined with range hints: name: %s, type: %s, hint: %s" % [
                property.name, property.type, property.hint
            ]):
        return

    var row: ScaffolderSettingsRow
    match property.type:
        TYPE_BOOL:
            row = checkbox_row_scene.instantiate()
        TYPE_INT, \
        TYPE_FLOAT:
            row = slider_row_scene.instantiate()
        _:
            S.utils.ensure(false,
                "Unsupported settings property type: name: %s, type: %s, hint: %s" % [
                    property.name, property.type, property.hint
                ])
            return null

    row.set_up(property, SLIDER_WIDTH)
    return row


func _on_close_button_pressed() -> void:
    S.screens.close(self)
