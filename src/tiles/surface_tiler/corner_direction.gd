class_name CornerDirection


enum {
    UNKNOWN,
    
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
    
    INBOUND_TL_T,
    INBOUND_TL_L,
    INBOUND_TR_T,
    INBOUND_TR_R,
    INBOUND_BL_B,
    INBOUND_BL_L,
    INBOUND_BR_B,
    INBOUND_BR_R,
}

const OUTBOUND_CORNERS := [
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
]

const INBOUND_CORNERS := [
    INBOUND_TL_T,
    INBOUND_TL_L,
    INBOUND_TR_T,
    INBOUND_TR_R,
    INBOUND_BL_B,
    INBOUND_BL_L,
    INBOUND_BR_B,
    INBOUND_BR_R,
]

const KEYS := [
    UNKNOWN,
    
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
    
    INBOUND_TL_T,
    INBOUND_TL_L,
    INBOUND_TR_T,
    INBOUND_TR_R,
    INBOUND_BL_B,
    INBOUND_BL_L,
    INBOUND_BR_B,
    INBOUND_BR_R,
]

static func get_string(type: int) -> String:
    match type:
        UNKNOWN:
            return "UNKNOWN"
        TOP_LEFT:
            return "TOP_LEFT"
        TOP_RIGHT:
            return "TOP_RIGHT"
        BOTTOM_LEFT:
            return "BOTTOM_LEFT"
        BOTTOM_RIGHT:
            return "BOTTOM_RIGHT"
        INBOUND_TL_T:
            return "INBOUND_TL_T"
        INBOUND_TL_L:
            return "INBOUND_TL_L"
        INBOUND_TR_T:
            return "INBOUND_TR_T"
        INBOUND_TR_R:
            return "INBOUND_TR_R"
        INBOUND_BL_B:
            return "INBOUND_BL_B"
        INBOUND_BL_L:
            return "INBOUND_BL_L"
        INBOUND_BR_B:
            return "INBOUND_BR_B"
        INBOUND_BR_R:
            return "INBOUND_BR_R"
        _:
            Sc.logger.error("CornerDirection.get_string")
            return "??"


static func get_is_top(type: int) -> bool:
    match type:
        UNKNOWN:
            return false
        TOP_LEFT, \
        TOP_RIGHT:
            return true
        BOTTOM_LEFT, \
        BOTTOM_RIGHT:
            return false
        INBOUND_TL_T, \
        INBOUND_TL_L, \
        INBOUND_TR_T, \
        INBOUND_TR_R, \
        INBOUND_BL_B, \
        INBOUND_BL_L, \
        INBOUND_BR_B, \
        INBOUND_BR_R:
            return false
        _:
            Sc.logger.error("CornerDirection.get_is_top")
            return false


static func get_is_left(type: int) -> bool:
    match type:
        UNKNOWN:
            return false
        TOP_LEFT, \
        BOTTOM_LEFT:
            return true
        TOP_RIGHT, \
        BOTTOM_RIGHT:
            return false
        INBOUND_TL_T, \
        INBOUND_TL_L, \
        INBOUND_TR_T, \
        INBOUND_TR_R, \
        INBOUND_BL_B, \
        INBOUND_BL_L, \
        INBOUND_BR_B, \
        INBOUND_BR_R:
            return false
        _:
            Sc.logger.error("CornerDirection.get_is_left")
            return false


static func get_is_outbound(type: int) -> bool:
    match type:
        UNKNOWN:
            return false
        TOP_LEFT, \
        BOTTOM_LEFT, \
        TOP_RIGHT, \
        BOTTOM_RIGHT:
            return true
        INBOUND_TL_T, \
        INBOUND_TL_L, \
        INBOUND_TR_T, \
        INBOUND_TR_R, \
        INBOUND_BL_B, \
        INBOUND_BL_L, \
        INBOUND_BR_B, \
        INBOUND_BR_R:
            return false
        _:
            Sc.logger.error("CornerDirection.get_is_outbound")
            return false


static func get_is_horizontal_inbound(type: int) -> bool:
    match type:
        UNKNOWN:
            return false
        TOP_LEFT, \
        BOTTOM_LEFT, \
        TOP_RIGHT, \
        BOTTOM_RIGHT:
            return false
        INBOUND_TL_T, \
        INBOUND_TR_T, \
        INBOUND_BL_B, \
        INBOUND_BR_B:
            return false
        INBOUND_TL_L, \
        INBOUND_TR_R, \
        INBOUND_BL_L, \
        INBOUND_BR_R:
            return true
        _:
            Sc.logger.error("CornerDirection.get_is_horizontal_inbound")
            return false


static func get_outbound_from_inbound(inbound_corner: int) -> int:
    match inbound_corner:
        INBOUND_TL_T, \
        INBOUND_TL_L:
            return TOP_LEFT
        INBOUND_TR_T, \
        INBOUND_TR_R:
            return TOP_RIGHT
        INBOUND_BL_B, \
        INBOUND_BL_L:
            return BOTTOM_LEFT
        INBOUND_BR_B, \
        INBOUND_BR_R:
            return BOTTOM_RIGHT
        UNKNOWN, \
        TOP_LEFT, \
        BOTTOM_LEFT, \
        TOP_RIGHT, \
        BOTTOM_RIGHT, \
        _:
            Sc.logger.error("CornerDirection.get_outbound_from_inbound")
            return UNKNOWN


static func get_horizontal_flip(corner_direction: int) -> int:
    match corner_direction:
        INBOUND_TL_T:
            return INBOUND_TR_T
        INBOUND_TL_L:
            return INBOUND_TR_R
        INBOUND_TR_T:
            return INBOUND_TL_T
        INBOUND_TR_R:
            return INBOUND_TL_L
        INBOUND_BL_B:
            return INBOUND_BR_B
        INBOUND_BL_L:
            return INBOUND_BR_R
        INBOUND_BR_B:
            return INBOUND_BL_B
        INBOUND_BR_R:
            return INBOUND_BL_L
        TOP_LEFT:
            return TOP_RIGHT
        BOTTOM_LEFT:
            return BOTTOM_RIGHT
        TOP_RIGHT:
            return TOP_LEFT
        BOTTOM_RIGHT:
            return BOTTOM_LEFT
        UNKNOWN:
            return UNKNOWN
        _:
            Sc.logger.error("CornerDirection.get_horizontal_flip")
            return UNKNOWN


static func get_vertical_flip(corner_direction: int) -> int:
    match corner_direction:
        INBOUND_TL_T:
            return INBOUND_BL_B
        INBOUND_TL_L:
            return INBOUND_BL_L
        INBOUND_TR_T:
            return INBOUND_BR_B
        INBOUND_TR_R:
            return INBOUND_BR_R
        INBOUND_BL_B:
            return INBOUND_TL_T
        INBOUND_BL_L:
            return INBOUND_TL_L
        INBOUND_BR_B:
            return INBOUND_TR_T
        INBOUND_BR_R:
            return INBOUND_TR_R
        TOP_LEFT:
            return BOTTOM_LEFT
        BOTTOM_LEFT:
            return TOP_LEFT
        TOP_RIGHT:
            return BOTTOM_RIGHT
        BOTTOM_RIGHT:
            return TOP_RIGHT
        UNKNOWN:
            return UNKNOWN
        _:
            Sc.logger.error("CornerDirection.get_vertical_flip")
            return UNKNOWN
