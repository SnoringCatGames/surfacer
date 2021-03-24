extends LabeledControlItem
class_name TextLabeledControlItem

var TYPE := LabeledControlItem.TEXT

var text: String

func _init( \
        label: String, \
        description: String \
        ).( \
        TYPE, \
        label, \
        description \
        ) -> void:
    pass

func get_is_enabled() -> bool:
    return true

func get_text() -> String:
    Gs.utils.error( \
            "Abstract TextLabeledControlItem.get_text is not implemented")
    return ""
