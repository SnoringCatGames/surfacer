extends PlayerActionSource
class_name InstructionsActionSource

const InstructionsPlayback := preload("res://framework/player/instructions_playback.gd")

# Array<_InstructionsPlayback>
var _all_playback := []

func _init(player).(player) -> void:
    pass

# Calculates actions for the current frame.
func update(actions: PlayerActionState, time_sec: float, delta: float) -> void:
    var next_instruction: PlayerInstruction
    var is_pressed: bool
    var non_pressed_keys := []
    
    for playback in _all_playback:
        non_pressed_keys.clear()
        
        # Handle all previously started keys that are still pressed.
        for input_key in playback.active_key_presses:
            is_pressed = playback.active_key_presses[input_key]
            update_for_key_press(actions, input_key, is_pressed, time_sec)
            if !is_pressed:
                non_pressed_keys.push_back(input_key)
        
        # Remove from the active set all keys that are no longer pressed.
        for input_key in non_pressed_keys:
            playback.update_for_key_press.erase(input_key)
        
        # Handle any new key presses.
        while !playback.is_finished and playback.next_instruction.time <= time_sec:
            update_for_key_press(actions, playback.next_instruction.input_key, \
                    playback.next_instruction.is_pressed, time_sec)
            playback.increment()
    
    # Handle instructions that finish.
    var i := 0
    while i < _all_playback.size():
        if _all_playback[i].is_finished:
            _all_playback.remove(i)
            i -= 1
        i += 1

func start_instructions(instructions: PlayerInstructions) -> InstructionsPlayback:
    var playback := InstructionsPlayback.new(instructions)
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
