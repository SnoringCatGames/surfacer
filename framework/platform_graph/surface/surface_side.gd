class_name SurfaceSide

enum {
    NONE,
    FLOOR,
    CEILING,
    LEFT_WALL,
    RIGHT_WALL,
}

static func to_string(side: int) -> String:
    match side:
        NONE:
            return "NONE"
        FLOOR:
            return "FLOOR"
        CEILING:
            return "CEILING"
        LEFT_WALL:
            return "LEFT_WALL"
        RIGHT_WALL:
            return "RIGHT_WALL"
        _:
            return "???"
