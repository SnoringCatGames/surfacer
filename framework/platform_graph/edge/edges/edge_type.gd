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
        _:
            Utils.error("Invalid EdgeType: %s" % type)
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
]
static func keys() -> Array:
    return KEYS
