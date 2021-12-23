class_name SurfaceReachability


enum {
    ANY,
    REACHABLE,
    REVERSIBLY_REACHABLE,
}


static func get_string(side: int) -> String:
    match side:
        ANY:
            return "ANY"
        REACHABLE:
            return "REACHABLE"
        REVERSIBLY_REACHABLE:
            return "REVERSIBLY_REACHABLE"
        _:
            Sc.logger.error("Invalid SurfaceReachability: %s" % side)
            return "???"
