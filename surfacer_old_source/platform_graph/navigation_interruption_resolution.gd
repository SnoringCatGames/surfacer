class_name NavigationInterruptionResolution


enum {
    UNKNOWN,
    CANCEL_NAV,
    RETRY_NAV,
    SKIP_NAV,
    FORCE_EXPECTED_STATE,
}


static func get_string(type: int) -> String:
    match type:
        UNKNOWN:
            return "UNKNOWN"
        CANCEL_NAV:
            return "CANCEL_NAV"
        RETRY_NAV:
            return "RETRY_NAV"
        SKIP_NAV:
            return "SKIP_NAV"
        FORCE_EXPECTED_STATE:
            return "FORCE_EXPECTED_STATE"
        _:
            Sc.logger.error(
                    "Invalid NavigationInterruptionResolution: %s" % type)
            return "???"
