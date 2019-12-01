extends Reference
class_name PlayerActionState

var delta: float

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

var start_dash := false

func clear() -> void:
    self.delta = INF
    
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
    
    self.start_dash = false

func copy(other: PlayerActionState) -> void:
    self.delta = other.delta
    
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
    
    self.start_dash = other.start_dash
