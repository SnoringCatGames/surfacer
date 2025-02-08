class_name ScaffolderSliderSettingsRow
extends ScaffolderSettingsRow


func set_up(property: Dictionary, value_width: float) -> void:
    super(property, value_width)

    if not S.utils.ensure(property.type == TYPE_BOOL or property.type == TYPE_FLOAT):
        return
    if not S.utils.ensure(property.hint == PropertyHint.PROPERTY_HINT_RANGE,
            "Numeric settings properties must be annotated with ranges."):
        return

    var hint_string: String = property.hint_string
    var hint_tokens := hint_string.split_floats(",")
    if not S.utils.ensure(hint_tokens.size() == 2 or hint_tokens.size() == 3,
            "Invalid range hint format for settings property."):
        return

    var min := hint_tokens[0]
    var max := hint_tokens[1]
    var step: float = hint_tokens[2] if hint_tokens.size() == 3 else 0

    var value: float = S.settings.get(property.name)

    %ClickHSlider.min_value = min
    %ClickHSlider.max_value = max
    %ClickHSlider.step = step
    %ClickHSlider.value = value

    %ClickHSlider.custom_minimum_size.x = value_width


func _on_click_h_slider_value_changed(value: float) -> void:
    S.settings.update_property(property_name, value)
