class_name ScaffolderCheckboxSettingsRow
extends ScaffolderSettingsRow


signal toggled(toggled_on: bool)


func set_up(property: Dictionary, value_width: float) -> void:
    super(property, value_width)

    assert(property.type == TYPE_BOOL)

    var value: bool = S.settings.get(property.name)
    %ClickCheckBox.button_pressed = value


func _on_click_check_box_toggled(toggled_on: bool) -> void:
    S.settings.update_property(property_name, toggled_on)
    toggled.emit(toggled_on)
