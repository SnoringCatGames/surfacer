extends PlayerActionSource
class_name InstructionsActionSource

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
        while playback.next_instruction != null and playback.next_instruction.time <= time_sec:
            update_for_key_press(actions, playback.next_instruction.input_key, \
                    playback.next_instruction.is_pressed, time_sec)
            playback.increment()
    
    # Handle instructions that finish.
    var i := 0
    while i < _all_playback.size():
        if _all_playback[i].next_instruction == null:
            _all_playback.remove(i)
            i -= 1
        i += 1

func start_instructions(instructions: PlayerInstructions) -> void:
    assert(_check_instructions(instructions))
    _all_playback.push_back(_InstructionsPlayback.new(instructions))

func cancel_instructions(instructions: PlayerInstructions) -> bool:
    var index := -1
    for i in range(_all_playback.size()):
        if _all_playback[i].instructions == instructions:
            index = i
            break
    
    if index < 0:
        return false
    else:
        _all_playback.remove(index)
        return true

func cancel_all_instructions() -> void:
    _all_playback.clear()

func _check_instructions(instructions: PlayerInstructions) -> bool:
    # Dictionary<String, boolean>
    var active_key_presses := {}
    var is_pressed_count := 0
    for instruction in instructions.instructions:
        if instruction.is_pressed:
            active_key_presses[instruction.input_key] = true
            is_pressed_count += 1
        else:
            assert(active_key_presses[instruction.input_key])
            active_key_presses[instruction.input_key] = false
            is_pressed_count -= 1
    
    assert(is_pressed_count == 0)
    assert(instructions.instructions.back().time == instructions.duration)
    
    return true

class _InstructionsPlayback extends Reference:
    var instructions: PlayerInstructions
    var next_index := 0
    var next_instruction: PlayerInstruction
    # Dictionary<String, boolean>
    var active_key_presses := {}
    
    func _init(instructions: PlayerInstructions) -> void:
        assert(!instructions.empty())
        self.instructions = instructions
        self.next_instruction = instructions.instructions[0]
    
    func increment() -> void:
        # Update the set of active key presses.
        if next_instruction.is_pressed:
            active_key_presses[next_instruction.input_key] = true
        else:
            active_key_presses[next_instruction.input_key] = false
        
        next_index += 1
        next_instruction = instructions.instructions[next_index] if \
                instructions.instructions.size() > next_index else null
