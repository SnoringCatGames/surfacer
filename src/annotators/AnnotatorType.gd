class_name AnnotatorType

enum {
    RULER,
    SURFACES,
    GRID_INDICES,
    LEVEL,
    PLAYER,
    PLAYER_POSITION,
    PLAYER_TRAJECTORY,
    NAVIGATOR,
    CLICK,
    SURFACE_SELECTION,
    UNKNOWN,
}

static func get_string(type: int) -> String:
    match type:
        RULER:
            return "RULER"
        SURFACES:
            return "SURFACES"
        GRID_INDICES:
            return "GRID_INDICES"
        LEVEL:
            return "LEVEL"
        PLAYER:
            return "PLAYER"
        PLAYER_POSITION:
            return "PLAYER_POSITION"
        PLAYER_TRAJECTORY:
            return "PLAYER_TRAJECTORY"
        NAVIGATOR:
            return "NAVIGATOR"
        CLICK:
            return "CLICK"
        SURFACE_SELECTION:
            return "SURFACE_SELECTION"
        UNKNOWN:
            return "UNKNOWN"
        _:
            Gs.utils.error("Invalid AnnotatorType: %s" % type)
            return "???"

static func get_settings_key(type: int) -> String:
    return get_string(type) + "_enabled"
