class_name CharacterActionState
extends Reference


var delta_scaled: float

var pressed_jump := false
var just_pressed_jump := false
var just_released_jump := false

var pressed_up := false
var just_pressed_up := false
var just_released_up := false

var pressed_down := false
var just_pressed_down := false
var just_released_down := false

var pressed_left := false
var just_pressed_left := false
var just_released_left := false

var pressed_right := false
var just_pressed_right := false
var just_released_right := false

var pressed_grab := false
var just_pressed_grab := false
var just_released_grab_wall := false

var pressed_face_left := false
var just_pressed_face_left := false
var just_released_face_left := false

var pressed_face_right := false
var just_pressed_face_right := false
var just_released_face_right := false

var start_dash := false


func clear() -> void:
    self.delta_scaled = INF
    
    self.pressed_jump = false
    self.just_pressed_jump = false
    self.just_released_jump = false
    
    self.pressed_up = false
    self.just_pressed_up = false
    self.just_released_up = false
    
    self.pressed_down = false
    self.just_pressed_down = false
    self.just_released_down = false
    
    self.pressed_left = false
    self.just_pressed_left = false
    self.just_released_left = false
    
    self.pressed_right = false
    self.just_pressed_right = false
    self.just_released_right = false
    
    self.pressed_grab = false
    self.just_pressed_grab = false
    self.just_released_grab_wall = false
    
    self.pressed_face_left = false
    self.just_pressed_face_left = false
    self.just_released_face_left = false
    
    self.pressed_face_right = false
    self.just_pressed_face_right = false
    self.just_released_face_right = false
    
    self.start_dash = false


func copy(other: CharacterActionState) -> void:
    self.delta_scaled = other.delta_scaled
    
    self.pressed_jump = other.pressed_jump
    self.just_pressed_jump = other.just_pressed_jump
    self.just_released_jump = other.just_released_jump
    
    self.pressed_up = other.pressed_up
    self.just_pressed_up = other.just_pressed_up
    self.just_released_up = other.just_released_up
    
    self.pressed_down = other.pressed_down
    self.just_pressed_down = other.just_pressed_down
    self.just_released_down = other.just_released_down
    
    self.pressed_left = other.pressed_left
    self.just_pressed_left = other.just_pressed_left
    self.just_released_left = other.just_released_left
    
    self.pressed_right = other.pressed_right
    self.just_pressed_right = other.just_pressed_right
    self.just_released_right = other.just_released_right
    
    self.pressed_grab = other.pressed_grab
    self.just_pressed_grab = other.just_pressed_grab
    self.just_released_grab_wall = other.just_released_grab_wall
    
    self.pressed_face_left = other.pressed_face_left
    self.just_pressed_face_left = other.just_pressed_face_left
    self.just_released_face_left = other.just_released_face_left
    
    self.pressed_face_right = other.pressed_face_right
    self.just_pressed_face_right = other.just_pressed_face_right
    self.just_released_face_right = other.just_released_face_right
    
    self.start_dash = other.start_dash


func log_new_presses_and_releases(character) -> void:
    _log_new_press_or_release(
            character,
            "jump",
            just_pressed_jump,
            just_released_jump)
    _log_new_press_or_release(
            character,
            "up",
            just_pressed_up,
            just_released_up)
    _log_new_press_or_release(
            character,
            "down",
            just_pressed_down,
            just_released_down)
    _log_new_press_or_release(
            character,
            "left",
            just_pressed_left,
            just_released_left)
    _log_new_press_or_release(
            character,
            "right",
            just_pressed_right,
            just_released_right)
    _log_new_press_or_release(
            character,
            "grab",
            just_pressed_grab,
            just_released_grab_wall)
    _log_new_press_or_release(
            character,
            "faceL",
            just_pressed_face_left,
            just_released_face_left)
    _log_new_press_or_release(
            character,
            "faceR",
            just_pressed_face_right,
            just_released_face_right)
    _log_new_press_or_release(
            character,
            "dash",
            start_dash,
            false)


static func _log_new_press_or_release(
        character,
        action_name: String,
        just_pressed: bool,
        just_released: bool) -> void:
    if just_pressed:
        character._log(
                "START %5s" % action_name,
                "",
                CharacterLogType.ACTION,
                false)
    if just_released:
        character._log(
                "STOP  %5s" % action_name,
                "",
                CharacterLogType.ACTION,
                false)
