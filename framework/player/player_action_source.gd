extends Reference
class_name PlayerActionSource

var player # TODO: Add type back in

func _init(player) -> void:
    self.player = player

# Calculates actions for the current frame.
func update(actions: PlayerActionState, time_sec: float, delta: float) -> void:
    Utils.error("Abstract PlayerActionSource.update is not implemented")

func update_for_key_press(actions: PlayerActionState, input_key: String, is_pressed: bool, \
        time_sec: float) -> void:
    var was_pressed: bool
    var just_pressed: bool
    var just_released: bool
    var print_label: String
    
    match input_key:
        "jump":
            was_pressed = actions.pressed_jump
            just_pressed = !was_pressed and is_pressed
            just_released = was_pressed and !is_pressed
            actions.pressed_jump = is_pressed
            actions.just_pressed_jump = just_pressed
            actions.just_released_jump = just_released
            print_label = "jump"
        "move_up":
            was_pressed = actions.pressed_up
            just_pressed = !was_pressed and is_pressed
            just_released = was_pressed and !is_pressed
            actions.pressed_up = is_pressed
            actions.just_pressed_up = just_pressed
            actions.just_released_up = just_released
            print_label = "up"
        "move_down":
            was_pressed = actions.pressed_down
            just_pressed = !was_pressed and is_pressed
            just_released = was_pressed and !is_pressed
            actions.pressed_down = is_pressed
            actions.just_pressed_down = just_pressed
            actions.just_released_down = just_released
            print_label = "down"
        "move_left":
            was_pressed = actions.pressed_left
            just_pressed = !was_pressed and is_pressed
            just_released = was_pressed and !is_pressed
            actions.pressed_left = is_pressed
            actions.just_pressed_left = just_pressed
            actions.just_released_left = just_released
            print_label = "left"
        "move_right":
            was_pressed = actions.pressed_right
            just_pressed = !was_pressed and is_pressed
            just_released = was_pressed and !is_pressed
            actions.pressed_right = is_pressed
            actions.just_pressed_right = just_pressed
            actions.just_released_right = just_released
            print_label = "right"
        _:
            Utils.error("Invalid input_key: %s" % input_key)
    
    # Uncomment to help with debugging.
    if just_pressed:
        print("CP START %7s%8.3f:%29sP:%29sV" % \
                [print_label + ":", time_sec, player.position, player.velocity])
    if just_released:
        print("CP STOP  %7s%8.3f:%29sP:%29sV" % \
                [print_label + ":", time_sec, player.position, player.velocity])