class_name EdgeType

enum {
    AIR_TO_AIR_EDGE,
    AIR_TO_SURFACE_EDGE,
    CLIMB_DOWN_WALL_TO_FLOOR_EDGE,
    CLIMB_OVER_WALL_TO_FLOOR_EDGE,
    FALL_FROM_FLOOR_EDGE,
    FALL_FROM_WALL_EDGE,
    INTRA_SURFACE_EDGE,
    JUMP_FROM_SURFACE_TO_AIR_EDGE,
    JUMP_INTER_SURFACE_EDGE,
    WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE,
    UNKNOWN,
}

static func get_type_string(type: int) -> String:
    match type:
        AIR_TO_AIR_EDGE:
            return "AIR_TO_AIR_EDGE"
        AIR_TO_SURFACE_EDGE:
            return "AIR_TO_SURFACE_EDGE"
        CLIMB_DOWN_WALL_TO_FLOOR_EDGE:
            return "CLIMB_DOWN_WALL_TO_FLOOR_EDGE"
        CLIMB_OVER_WALL_TO_FLOOR_EDGE:
            return "CLIMB_OVER_WALL_TO_FLOOR_EDGE"
        FALL_FROM_FLOOR_EDGE:
            return "FALL_FROM_FLOOR_EDGE"
        FALL_FROM_WALL_EDGE:
            return "FALL_FROM_WALL_EDGE"
        INTRA_SURFACE_EDGE:
            return "INTRA_SURFACE_EDGE"
        JUMP_FROM_SURFACE_TO_AIR_EDGE:
            return "JUMP_FROM_SURFACE_TO_AIR_EDGE"
        JUMP_INTER_SURFACE_EDGE:
            return "JUMP_INTER_SURFACE_EDGE"
        WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE:
            return "WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE"
        UNKNOWN:
            return "UNKNOWN"
        _:
            ScaffoldUtils.error("Invalid EdgeType: %s" % type)
            return "???"

static func get_description_string(type: int) -> String:
    match type:
        AIR_TO_AIR_EDGE:
            return "An AIR_TO_AIR_EDGE represents movement from one air " + \
                    "position to another."
        AIR_TO_SURFACE_EDGE:
            return "An AIR_TO_SURFACE_EDGE represents movement from an " + \
                    "air position to land on a surface position."
        CLIMB_DOWN_WALL_TO_FLOOR_EDGE:
            return "A CLIMB_DOWN_WALL_TO_FLOOR_EDGE represents movement " + \
                    "from climbing down a wall to an adjacent floor to " + \
                    "then release the wall and stand on the floor."
        CLIMB_OVER_WALL_TO_FLOOR_EDGE:
            return "A CLIMB_OVER_WALL_TO_FLOOR_EDGE represents movement " + \
                    "from climbing up over the top end of a wall in order " + \
                    "to then stand on the adjacent floor."
        FALL_FROM_FLOOR_EDGE:
            return "A FALL_FROM_FLOOR_EDGE represents movement from " + \
                    "falling off the end of a floor surface to land on " + \
                    "some other surface."
        FALL_FROM_WALL_EDGE:
            return "A FALL_FROM_WALL_EDGE represents movement from " + \
                    "falling off a wall surface to land on some other surface."
        INTRA_SURFACE_EDGE:
            return "An INTRA_SURFACE_EDGE represents movement between two " + \
                    "points along the same surface."
        JUMP_FROM_SURFACE_TO_AIR_EDGE:
            return "A JUMP_FROM_SURFACE_TO_AIR_EDGE represents movement " + \
                    "from jumping from a surface position to a position " + \
                    "in the air."
        JUMP_INTER_SURFACE_EDGE:
            return "A JUMP_INTER_SURFACE_EDGE represents movement from " + \
                    "jumping between two surface positions."
        WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE:
            return "A WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE represents " + \
                    "movement from walking along a floor to an adjacent " +\
                    "upward wall to then grab onto the wall."
        UNKNOWN:
            return "UNKNOWN"
        _:
            ScaffoldUtils.error("Invalid EdgeType: %s" % type)
            return "???"

const KEYS = [
    "AIR_TO_AIR_EDGE",
    "AIR_TO_SURFACE_EDGE",
    "CLIMB_DOWN_WALL_TO_FLOOR_EDGE",
    "CLIMB_OVER_WALL_TO_FLOOR_EDGE",
    "FALL_FROM_FLOOR_EDGE",
    "FALL_FROM_WALL_EDGE",
    "INTRA_SURFACE_EDGE",
    "JUMP_FROM_SURFACE_TO_AIR_EDGE",
    "JUMP_INTER_SURFACE_EDGE",
    "WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE",
    "UNKNOWN",
]
static func keys() -> Array:
    return KEYS

const VALUES = [
    AIR_TO_AIR_EDGE,
    AIR_TO_SURFACE_EDGE,
    CLIMB_DOWN_WALL_TO_FLOOR_EDGE,
    CLIMB_OVER_WALL_TO_FLOOR_EDGE,
    FALL_FROM_FLOOR_EDGE,
    FALL_FROM_WALL_EDGE,
    INTRA_SURFACE_EDGE,
    JUMP_FROM_SURFACE_TO_AIR_EDGE,
    JUMP_INTER_SURFACE_EDGE,
    WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE,
    UNKNOWN,
]
static func values() -> Array:
    return VALUES
