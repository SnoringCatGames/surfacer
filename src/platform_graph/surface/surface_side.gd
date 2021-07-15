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
            Sc.logger.error("Invalid SurfaceSide: %s" % side)
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
            Sc.logger.error("Invalid SurfaceSide: %s" % side)
            return "???"


static func get_normal(side: int) -> Vector2:
    return \
            Sc.geometry.UP if side == FLOOR else (
            Sc.geometry.DOWN if side == CEILING else (
            Sc.geometry.RIGHT if side == LEFT_WALL else (
            Sc.geometry.LEFT)))

const KEYS = [
    "NONE",
    "FLOOR",
    "CEILING",
    "LEFT_WALL",
    "RIGHT_WALL",
]
static func keys() -> Array:
    return KEYS
