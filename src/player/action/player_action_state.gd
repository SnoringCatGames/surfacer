class_name PlayerActionState
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

var pressed_grab_wall := false
var just_pressed_grab_wall := false
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
    
    self.pressed_grab_wall = false
    self.just_pressed_grab_wall = false
    self.just_released_grab_wall = false
    
    self.pressed_face_left = false
    self.just_pressed_face_left = false
    self.just_released_face_left = false
    
    self.pressed_face_right = false
    self.just_pressed_face_right = false
    self.just_released_face_right = false
    
    self.start_dash = false


func copy(other: PlayerActionState) -> void:
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
    
    self.pressed_grab_wall = other.pressed_grab_wall
    self.just_pressed_grab_wall = other.just_pressed_grab_wall
    self.just_released_grab_wall = other.just_released_grab_wall
    
    self.pressed_face_left = other.pressed_face_left
    self.just_pressed_face_left = other.just_pressed_face_left
    self.just_released_face_left = other.just_released_face_left
    
    self.pressed_face_right = other.pressed_face_right
    self.just_pressed_face_right = other.just_pressed_face_right
    self.just_released_face_right = other.just_released_face_right
    
    self.start_dash = other.start_dash


func log_new_presses_and_releases(
        player,
        time: float) -> void:
    _log_new_press_or_release(
            player,
            "jump",
            just_pressed_jump,
            just_released_jump,
            time)
    _log_new_press_or_release(
            player,
            "up",
            just_pressed_up,
            just_released_up,
            time)
    _log_new_press_or_release(
            player,
            "down",
            just_pressed_down,
            just_released_down,
            time)
    _log_new_press_or_release(
            player,
            "left",
            just_pressed_left,
            just_released_left,
            time)
    _log_new_press_or_release(
            player,
            "right",
            just_pressed_right,
            just_released_right,
            time)
    _log_new_press_or_release(
            player,
            "grab",
            just_pressed_grab_wall,
            just_released_grab_wall,
            time)
    _log_new_press_or_release(
            player,
            "faceL",
            just_pressed_face_left,
            just_released_face_left,
            time)
    _log_new_press_or_release(
            player,
            "faceR",
            just_pressed_face_right,
            just_released_face_right,
            time)
    _log_new_press_or_release(
            player,
            "dash",
            start_dash,
            false,
            time)


static func _log_new_press_or_release(
        player,
        action_name: String,
        just_pressed: bool,
        just_released: bool,
        time: float) -> void:
    var message_args := [
        action_name,
        player.player_name,
        time,
        player.surface_state.center_position,
        player.velocity,
    ]
    if just_pressed:
        player._log(
                "START %5s:%8s;%8.3fs;P%29s;V%29s" % message_args,
                PlayerLogType.ACTION,
                true)
    if just_released:
        player._log(
                "STOP  %5s:%8s;%8.3fs;P%29s;V%29s" % message_args,
                PlayerLogType.ACTION,
                true)
