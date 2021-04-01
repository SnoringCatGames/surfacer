class_name ColorParamsType

enum { \
    HSV, \
    HSV_RANGE, \
    UNKNOWN, \
}

static func get_string(type: int) -> String:
    match type:
        HSV:
            return "HSV"
        HSV_RANGE:
            return "HSV_RANGE"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Gs.utils.error("Invalid ColorParamsType: %s" % type)
            return ""
