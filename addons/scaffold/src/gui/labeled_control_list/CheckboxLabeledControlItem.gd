class_name CheckboxLabeledControlItem
extends LabeledControlItem

var TYPE := LabeledControlItem.CHECKBOX

var pressed := false

func _init( \
        label: String, \
        description: String \
        ).( \
        TYPE, \
        label, \
        description \
        ) -> void:
    pass

func on_pressed(pressed: bool) -> void:
    Gs.utils.error( \
            "Abstract CheckboxLabeledControlItem.on_pressed " + \
            "is not implemented")

func get_is_pressed() -> bool:
    Gs.utils.error( \
            "Abstract CheckboxLabeledControlItem.get_is_pressed " + \
            "is not implemented")
    return false
