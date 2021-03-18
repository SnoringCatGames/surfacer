class_name LabeledControlItemType

enum {
    TEXT,
    CHECKBOX,
    DROPDOWN,
}

static func get_type_string(type: int) -> String:
    match type:
        TEXT:
            return "TEXT"
        CHECKBOX:
            return "CHECKBOX"
        DROPDOWN:
            return "DROPDOWN"
        _:
            ScaffoldUtils.error("Invalid LabeledControlItemType: %s" % type)
            return "???"
