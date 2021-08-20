class_name SurfaceType


enum {
    FLOOR,
    WALL,
    CEILING,
    AIR,
    OTHER,
}


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
