class_name BehaviorMoveResult


enum {
    ERROR,
    REACHED_MAX_DISTANCE,
    VALID_MOVE,
    INVALID_MOVE,
}


static func get_string(type: int) -> String:
    match type:
        ERROR:
            return "ERROR"
        REACHED_MAX_DISTANCE:
            return "REACHED_MAX_DISTANCE"
        VALID_MOVE:
            return "VALID_MOVE"
        INVALID_MOVE:
            return "INVALID_MOVE"
        _:
            Sc.logger.error("Invalid BehaviorMoveResult: %s" % type)
            return "???"
