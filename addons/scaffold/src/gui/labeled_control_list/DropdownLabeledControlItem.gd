extends LabeledControlItem
class_name DropdownLabeledControlItem

var TYPE := LabeledControlItem.DROPDOWN

# Array<String>
var options: Array
var selected_index := -1

func _init( \
        label: String, \
        description: String \
        ).( \
        TYPE, \
        label, \
        description \
        ) -> void:
    pass

func on_selected(selected_index: int, selected_text: String) -> void:
    Gs.utils.error( \
            "Abstract DropdownLabeledControlItem.on_selected " + \
            "is not implemented")

func get_selected_index() -> bool:
    Gs.utils.error( \
            "Abstract DropdownLabeledControlItem.get_selected_index " + \
            "is not implemented")
    return false
