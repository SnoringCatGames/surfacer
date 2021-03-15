class_name PlayerActionType

enum {
    NONE,
    PRESSED_JUMP,
    RELEASED_JUMP,
    PRESSED_UP,
    RELEASED_UP,
    PRESSED_DOWN,
    RELEASED_DOWN,
    PRESSED_LEFT,
    RELEASED_LEFT,
    PRESSED_RIGHT,
    RELEASED_RIGHT,
    PRESSED_GRAB_WALL,
    RELEASED_GRAB_WALL,
    PRESSED_FACE_LEFT,
    RELEASED_FACE_LEFT,
    PRESSED_FACE_RIGHT,
    RELEASED_FACE_RIGHT,
}

static func get_type_string(type: int) -> String:
    match type:
        NONE:
            return "NONE"
        PRESSED_JUMP:
            return "PRESSED_JUMP"
        RELEASED_JUMP:
            return "RELEASED_JUMP"
        PRESSED_UP:
            return "PRESSED_UP"
        RELEASED_UP:
            return "RELEASED_UP"
        PRESSED_DOWN:
            return "PRESSED_DOWN"
        RELEASED_DOWN:
            return "RELEASED_DOWN"
        PRESSED_LEFT:
            return "PRESSED_LEFT"
        RELEASED_LEFT:
            return "RELEASED_LEFT"
        PRESSED_RIGHT:
            return "PRESSED_RIGHT"
        RELEASED_RIGHT:
            return "RELEASED_RIGHT"
        PRESSED_GRAB_WALL:
            return "PRESSED_GRAB_WALL"
        RELEASED_GRAB_WALL:
            return "RELEASED_GRAB_WALL"
        PRESSED_FACE_LEFT:
            return "PRESSED_FACE_LEFT"
        RELEASED_FACE_LEFT:
            return "RELEASED_FACE_LEFT"
        PRESSED_FACE_RIGHT:
            return "PRESSED_FACE_RIGHT"
        RELEASED_FACE_RIGHT:
            return "RELEASED_FACE_RIGHT"
        _:
            Utils.static_error()
            return "UNKNOWN"
