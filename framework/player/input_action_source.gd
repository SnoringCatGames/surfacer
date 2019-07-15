extends PlayerActionSource
class_name InputActionSource

# FIXME: LEFT OFF HERE

# Calculates actions for the current frame.
func update(actions: PlayerActionState, delta: float) -> void:
    var is_jump_pressed := Input.is_action_pressed("jump")
    var just_pressed_jump := !actions.pressed_jump and is_jump_pressed
    var just_released_jump := actions.pressed_jump and !is_jump_pressed
    
    var is_up_pressed := Input.is_action_pressed("move_up")
    var just_pressed_up := !actions.pressed_up and is_up_pressed
    var just_released_up := actions.pressed_up and !is_up_pressed
    
    var is_down_pressed := Input.is_action_pressed("move_down")
    var just_pressed_down := !actions.pressed_down and is_down_pressed
    var just_released_down := actions.pressed_down and !is_down_pressed
    
    var is_left_pressed := Input.is_action_pressed("move_left")
    var just_pressed_left := !actions.pressed_left and is_left_pressed
    var just_released_left := actions.pressed_left and !is_left_pressed
    
    var is_right_pressed := Input.is_action_pressed("move_right")
    var just_pressed_right := !actions.pressed_right and is_right_pressed
    var just_released_right := actions.pressed_right and !is_right_pressed
    
    actions.just_pressed_jump = just_pressed_jump
    actions.pressed_jump = is_jump_pressed
    actions.pressed_up = is_up_pressed
    actions.pressed_down = is_down_pressed
    actions.pressed_left = is_left_pressed
    actions.pressed_right = is_right_pressed
    
    # Uncomment to help with debugging.
    if just_pressed_jump:
        print("START jump:  %8.3f:%29sP:%29sV" % \
                [OS.get_ticks_msec()/1000.0, position, velocity])
    if just_released_jump:
        print("STOP jump:   %8.3f:%29sP:%29sV" % \
                [OS.get_ticks_msec()/1000.0, position, velocity])
    if just_pressed_up:
        print("START up:    %8.3f:%29sP:%29sV" % \
                [OS.get_ticks_msec()/1000.0, position, velocity])
    if just_released_up:
        print("STOP up:     %8.3f:%29sP:%29sV" % \
                [OS.get_ticks_msec()/1000.0, position, velocity])
    if just_pressed_down:
        print("START down:  %8.3f:%29sP:%29sV" % \
                [OS.get_ticks_msec()/1000.0, position, velocity])
    if just_released_down:
        print("STOP down:   %8.3f:%29sP:%29sV" % \
                [OS.get_ticks_msec()/1000.0, position, velocity])
    if just_pressed_left:
        print("START left:  %8.3f:%29sP:%29sV" % \
                [OS.get_ticks_msec()/1000.0, position, velocity])
    if just_released_left:
        print("STOP left:   %8.3f:%29sP:%29sV" % \
                [OS.get_ticks_msec()/1000.0, position, velocity])
    if just_pressed_right:
        print("START right: %8.3f:%29sP:%29sV" % \
                [OS.get_ticks_msec()/1000.0, position, velocity])
    if just_released_right:
        print("STOP right:  %8.3f:%29sP:%29sV" % \
                [OS.get_ticks_msec()/1000.0, position, velocity])
