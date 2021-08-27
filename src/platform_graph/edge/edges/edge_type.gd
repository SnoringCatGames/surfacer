class_name EdgeType


enum {
    FROM_AIR_EDGE,
    CLIMB_TO_NEIGHBOR_SURFACE_EDGE,
    FALL_FROM_FLOOR_EDGE,
    FALL_FROM_WALL_EDGE,
    INTRA_SURFACE_EDGE,
    JUMP_FROM_SURFACE_EDGE,
    UNKNOWN,
}


static func get_string(type: int) -> String:
    match type:
        FROM_AIR_EDGE:
            return "FROM_AIR_EDGE"
        CLIMB_TO_NEIGHBOR_SURFACE_EDGE:
            return "CLIMB_TO_NEIGHBOR_SURFACE_EDGE"
        FALL_FROM_FLOOR_EDGE:
            return "FALL_FROM_FLOOR_EDGE"
        FALL_FROM_WALL_EDGE:
            return "FALL_FROM_WALL_EDGE"
        INTRA_SURFACE_EDGE:
            return "INTRA_SURFACE_EDGE"
        JUMP_FROM_SURFACE_EDGE:
            return "JUMP_FROM_SURFACE_EDGE"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Sc.logger.error("Invalid EdgeType: %s" % type)
            return "???"


static func get_description(type: int) -> String:
    match type:
        FROM_AIR_EDGE:
            return ("An FROM_AIR_EDGE represents movement from an " +
                    "air position to land on a surface position.")
        CLIMB_TO_NEIGHBOR_SURFACE_EDGE:
            return ("A CLIMB_TO_NEIGHBOR_SURFACE_EDGE represents movement " +
                    "from climbing around either an inside or outside " +
                    "corner to a neighbor surface.")
        FALL_FROM_FLOOR_EDGE:
            return ("A FALL_FROM_FLOOR_EDGE represents movement from " +
                    "falling off the end of a floor surface to land on " +
                    "some other surface.")
        FALL_FROM_WALL_EDGE:
            return ("A FALL_FROM_WALL_EDGE represents movement from " +
                    "falling off a wall surface to land on some other " +
                    "surface.")
        INTRA_SURFACE_EDGE:
            return ("An INTRA_SURFACE_EDGE represents movement between two " +
                    "points along the same surface.")
        JUMP_FROM_SURFACE_EDGE:
            return ("A JUMP_FROM_SURFACE_EDGE represents movement from " +
                    "jumping between two surface positions.")
        UNKNOWN:
            return "UNKNOWN"
        _:
            Sc.logger.error("Invalid EdgeType: %s" % type)
            return "???"

const KEYS = [
    "FROM_AIR_EDGE",
    "CLIMB_TO_NEIGHBOR_SURFACE_EDGE",
    "FALL_FROM_FLOOR_EDGE",
    "FALL_FROM_WALL_EDGE",
    "INTRA_SURFACE_EDGE",
    "JUMP_FROM_SURFACE_EDGE",
    "UNKNOWN",
]
static func keys() -> Array:
    return KEYS

const VALUES = [
    FROM_AIR_EDGE,
    CLIMB_TO_NEIGHBOR_SURFACE_EDGE,
    FALL_FROM_FLOOR_EDGE,
    FALL_FROM_WALL_EDGE,
    INTRA_SURFACE_EDGE,
    JUMP_FROM_SURFACE_EDGE,
    UNKNOWN,
]
static func values() -> Array:
    return VALUES
