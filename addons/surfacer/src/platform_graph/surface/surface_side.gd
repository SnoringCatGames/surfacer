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


static func get_type(string: String) -> int:
    match string:
        "NONE":
            return NONE
        "FLOOR":
            return FLOOR
        "CEILING":
            return CEILING
        "LEFT_WALL":
            return LEFT_WALL
        "RIGHT_WALL":
            return RIGHT_WALL
        _:
            Sc.logger.error("Invalid SurfaceSide: %s" % string)
            return NONE


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
    match side:
        NONE:
            return Vector2.INF
        FLOOR:
            return Sc.geometry.UP
        CEILING:
            return Sc.geometry.DOWN
        LEFT_WALL:
            return Sc.geometry.RIGHT
        RIGHT_WALL:
            return Sc.geometry.LEFT
        _:
            Sc.logger.error("Invalid SurfaceSide: %s" % side)
            return Vector2.INF


const KEYS = [
    "NONE",
    "FLOOR",
    "CEILING",
    "LEFT_WALL",
    "RIGHT_WALL",
]
static func keys() -> Array:
    return KEYS
