class_name CellAngleType


enum {
    UNKNOWN,
    EMPTY,
    A90,
    A45,
    A27,
}


func get_string(type: int) -> String:
    match type:
        UNKNOWN:
            return "UNKNOWN"
        EMPTY:
            return "EMPTY"
        A90:
            return "A90"
        A45:
            return "A45"
        A27:
            return "A27"
        _:
            Sc.logger.error()
            return "??"
