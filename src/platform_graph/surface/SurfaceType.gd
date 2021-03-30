class_name SurfaceType

enum {
    FLOOR,
    WALL,
    AIR,
    OTHER,
}

static func get_type_from_side(side: int) -> int:
    match side:
        SurfaceSide.FLOOR:
            return FLOOR
        SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
            return WALL
        SurfaceSide.CEILING:
            return OTHER
        SurfaceSide.NONE:
            return AIR
        _:
            Gs.utils.error()
            return INF as int
