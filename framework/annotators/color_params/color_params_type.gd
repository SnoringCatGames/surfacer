class_name ColorParamsType

enum { \
    HSV_RANGE, \
    UNKNOWN, \
}

static func get_type_string(type: int) -> String:
    match type:
        HSV_RANGE:
            return "HSV_RANGE"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Utils.error("Invalid ColorParamsType: %s" % type)
            return ""
