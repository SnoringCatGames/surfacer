class_name SurfaceSide

enum {
    NONE,
    FLOOR,
    CEILING,
    LEFT_WALL,
    RIGHT_WALL,
}

static func get_string(side: int) -> String:
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
            Gs.logger.error("Invalid SurfaceSide: %s" % side)
            return "???"

static func get_prefix(side: int) -> String:
    match side:
        NONE:
            return "N"
        FLOOR:
            return "F"
        CEILING:
            return "C"
        LEFT_WALL:
            return "LW"
        RIGHT_WALL:
            return "RW"
        _:
            Gs.logger.error("Invalid SurfaceSide: %s" % side)
            return "???"

static func get_normal(side: int) -> Vector2:
    return \
            Gs.geometry.UP if side == FLOOR else (
            Gs.geometry.DOWN if side == CEILING else (
            Gs.geometry.RIGHT if side == LEFT_WALL else (
            Gs.geometry.LEFT)))

const KEYS = [
    "NONE",
    "FLOOR",
    "CEILING",
    "LEFT_WALL",
    "RIGHT_WALL",
]
static func keys() -> Array:
    return KEYS
