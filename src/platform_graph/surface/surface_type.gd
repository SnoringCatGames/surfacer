class_name SurfaceType


enum {
    FLOOR,
    WALL,
    CEILING,
    AIR,
    OTHER,
}


static func get_string(type: int) -> String:
    match type:
        FLOOR:
            return "FLOOR"
        WALL:
            return "WALL"
        CEILING:
            return "CEILING"
        AIR:
            return "AIR"
        OTHER:
            return "OTHER"
        _:
            Sc.logger.error()
            return ""


static func get_prefix(type: int) -> String:
    match type:
        FLOOR:
            return "F"
        WALL:
            return "W"
        CEILING:
            return "C"
        AIR:
            return "A"
        OTHER:
            return "O"
        _:
            Sc.logger.error()
            return ""


static func get_type_from_side(side: int) -> int:
    match side:
        SurfaceSide.FLOOR:
            return FLOOR
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            return WALL
        SurfaceSide.CEILING:
            return CEILING
        SurfaceSide.NONE:
            return AIR
        _:
            Sc.logger.error()
            return INF as int
