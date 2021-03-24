extends LabeledControlItem
class_name StaticTextLabeledControlItem

var TYPE := LabeledControlItem.TEXT

var text: String

func _init( \
        label: String, \
        text: String, \
        description := "" \
        ).( \
        TYPE, \
        label, \
        description \
        ) -> void:
    self.text = text

func get_is_enabled() -> bool:
    return true

func get_text() -> String:
    return text
