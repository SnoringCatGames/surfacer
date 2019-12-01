extends PlayerActionSource
class_name InstructionsActionSource

const InstructionsPlayback := preload("res://framework/player/action/instructions_playback.gd")

# Array<InstructionsPlayback>
var _all_playback := []

func _init(player).("CP", player) -> void:
    pass

# Calculates actions for the current frame.
func update(actions: PlayerActionState, previous_actions: PlayerActionState, time_sec: float, \
        delta: float) -> void:
    var is_pressed: bool
    var non_pressed_keys := []
    
    for playback in _all_playback:
        # Handle any new key presses up till the current time.
        var new_instructions: Array = playback.update(time_sec)
        
        non_pressed_keys.clear()
        
        # Handle all previously started keys that are still pressed.
        for input_key in playback.active_key_presses:
            is_pressed = playback.active_key_presses[input_key]
            update_for_key_press(actions, previous_actions, input_key, is_pressed, time_sec)
            if !is_pressed:
                non_pressed_keys.push_back(input_key)
        
        # Remove from the active set all keys that are no longer pressed.
        for input_key in non_pressed_keys:
            playback.active_key_presses.erase(input_key)
    
    # Handle instructions that finish.
    var i := 0
    while i < _all_playback.size():
        if _all_playback[i].is_finished:
            _all_playback.remove(i)
            i -= 1
        i += 1

func start_instructions(instructions: MovementInstructions, \
        time_sec: float) -> InstructionsPlayback:
    var playback := InstructionsPlayback.new(instructions)
    playback.start(time_sec)
    _all_playback.push_back(playback)
    return playback

func cancel_playback(playback: InstructionsPlayback) -> bool:
    var index := _all_playback.find(playback)
    if index < 0:
        return false
    else:
        _all_playback.remove(index)
        return true

func cancel_all_playback() -> void:
    _all_playback.clear()
