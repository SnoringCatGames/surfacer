extends Reference
class_name PlayerActionSource

var source_type_prefix: String
var player
var is_additive: bool

func _init( \
        source_type_prefix: String, \
        player, \
        is_additive: bool) -> void:
    self.source_type_prefix = source_type_prefix
    self.player = player
    self.is_additive = is_additive

# Calculates actions for the current frame.
func update( \
        actions: PlayerActionState, \
        previous_actions: PlayerActionState, \
        time_sec: float, \
        delta_sec: float, \
        navigation_state: PlayerNavigationState) -> void:
    Utils.error("Abstract PlayerActionSource.update is not implemented")

static func update_for_key_press( \
        actions: PlayerActionState, \
        previous_actions: PlayerActionState, \
        input_key: String, \
        is_pressed: bool, \
        time_sec: float, \
        is_additive: bool) -> void:
    var was_pressed_in_previous_frame: bool
    var was_already_pressed_in_current_frame: bool
    var is_pressed_in_current_frame: bool
    var just_pressed: bool
    var just_released: bool
    
    match input_key:
        "jump":
            was_pressed_in_previous_frame = previous_actions.pressed_jump
            was_already_pressed_in_current_frame = actions.pressed_jump
            is_pressed_in_current_frame = \
                    is_pressed or \
                    (is_additive and was_already_pressed_in_current_frame)
            just_pressed = \
                    !was_pressed_in_previous_frame and \
                    is_pressed_in_current_frame
            just_released = \
                    was_pressed_in_previous_frame and \
                    !is_pressed_in_current_frame
            
            actions.pressed_jump = is_pressed_in_current_frame
            actions.just_pressed_jump = just_pressed
            actions.just_released_jump = just_released
        "move_up":
            was_pressed_in_previous_frame = previous_actions.pressed_up
            was_already_pressed_in_current_frame = actions.pressed_up
            is_pressed_in_current_frame = \
                    is_pressed or \
                    (is_additive and was_already_pressed_in_current_frame)
            just_pressed = \
                    !was_pressed_in_previous_frame and \
                    is_pressed_in_current_frame
            just_released = \
                    was_pressed_in_previous_frame and \
                    !is_pressed_in_current_frame
            
            actions.pressed_up = is_pressed_in_current_frame
            actions.just_pressed_up = just_pressed
            actions.just_released_up = just_released
        "move_down":
            was_pressed_in_previous_frame = previous_actions.pressed_down
            was_already_pressed_in_current_frame = actions.pressed_down
            is_pressed_in_current_frame = \
                    is_pressed or \
                    (is_additive and was_already_pressed_in_current_frame)
            just_pressed = \
                    !was_pressed_in_previous_frame and \
                    is_pressed_in_current_frame
            just_released = \
                    was_pressed_in_previous_frame and \
                    !is_pressed_in_current_frame
            
            actions.pressed_down = is_pressed_in_current_frame
            actions.just_pressed_down = just_pressed
            actions.just_released_down = just_released
        "move_left":
            was_pressed_in_previous_frame = previous_actions.pressed_left
            was_already_pressed_in_current_frame = actions.pressed_left
            is_pressed_in_current_frame = \
                    is_pressed or \
                    (is_additive and was_already_pressed_in_current_frame)
            just_pressed = \
                    !was_pressed_in_previous_frame and \
                    is_pressed_in_current_frame
            just_released = \
                    was_pressed_in_previous_frame and \
                    !is_pressed_in_current_frame
            
            actions.pressed_left = is_pressed_in_current_frame
            actions.just_pressed_left = just_pressed
            actions.just_released_left = just_released
        "move_right":
            was_pressed_in_previous_frame = previous_actions.pressed_right
            was_already_pressed_in_current_frame = actions.pressed_right
            is_pressed_in_current_frame = \
                    is_pressed or \
                    (is_additive and was_already_pressed_in_current_frame)
            just_pressed = \
                    !was_pressed_in_previous_frame and \
                    is_pressed_in_current_frame
            just_released = \
                    was_pressed_in_previous_frame and \
                    !is_pressed_in_current_frame
            
            actions.pressed_right = is_pressed_in_current_frame
            actions.just_pressed_right = just_pressed
            actions.just_released_right = just_released
        "grab_wall":
            was_pressed_in_previous_frame = previous_actions.pressed_grab_wall
            was_already_pressed_in_current_frame = actions.pressed_grab_wall
            is_pressed_in_current_frame = \
                    is_pressed or \
                    (is_additive and was_already_pressed_in_current_frame)
            just_pressed = \
                    !was_pressed_in_previous_frame and \
                    is_pressed_in_current_frame
            just_released = \
                    was_pressed_in_previous_frame and \
                    !is_pressed_in_current_frame
            
            actions.pressed_grab_wall = is_pressed_in_current_frame
            actions.just_pressed_grab_wall = just_pressed
            actions.just_released_grab_wall = just_released
        "face_left":
            was_pressed_in_previous_frame = previous_actions.pressed_face_left
            was_already_pressed_in_current_frame = actions.pressed_face_left
            is_pressed_in_current_frame = \
                    is_pressed or \
                    (is_additive and was_already_pressed_in_current_frame)
            just_pressed = \
                    !was_pressed_in_previous_frame and \
                    is_pressed_in_current_frame
            just_released = \
                    was_pressed_in_previous_frame and \
                    !is_pressed_in_current_frame
            
            actions.pressed_face_left = is_pressed_in_current_frame
            actions.just_pressed_face_left = just_pressed
            actions.just_released_face_left = just_released
        "face_right":
            was_pressed_in_previous_frame = previous_actions.pressed_face_right
            was_already_pressed_in_current_frame = actions.pressed_face_right
            is_pressed_in_current_frame = \
                    is_pressed or \
                    (is_additive and was_already_pressed_in_current_frame)
            just_pressed = \
                    !was_pressed_in_previous_frame and \
                    is_pressed_in_current_frame
            just_released = \
                    was_pressed_in_previous_frame and \
                    !is_pressed_in_current_frame
            
            actions.pressed_face_right = is_pressed_in_current_frame
            actions.just_pressed_face_right = just_pressed
            actions.just_released_face_right = just_released
        _:
            Utils.error("Invalid input_key: %s" % input_key)

static func input_key_to_action_name(input_key: String) -> String:
    match input_key:
        "jump":
            return "jump"
        "move_up":
            return "up"
        "move_down":
            return "down"
        "move_left":
            return "left"
        "move_right":
            return "right"
        "grab_wall":
            return "grab"
        "face_left":
            return "faceL"
        "face_right":
            return "faceR"
        _:
            Utils.error()
            return ""
