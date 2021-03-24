extends Reference
class_name LabeledControlItem

enum {
    TEXT,
    CHECKBOX,
    DROPDOWN,
}

var control: Control
var label: String
var type: int
var description: String
var enabled := true

func _init( \
        type: int, \
        label: String, \
        description: String) -> void:
    self.type = type
    self.label = label
    self.description = description

func get_is_enabled() -> bool:
    Gs.utils.error( \
            "Abstract LabeledControlItem.get_is_enabled is not implemented")
    return false
