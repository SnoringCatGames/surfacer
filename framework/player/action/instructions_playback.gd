extends Reference
class_name InstructionsPlayback

var instructions: MovementInstructions
var next_index: int
var next_instruction: MovementInstruction
var is_finished := false
var is_on_last_instruction := false
# Dictionary<String, boolean>
var active_key_presses := {}

var end_time_for_current_instruction: float setget ,_end_time_for_current_instruction

func _init(instructions: MovementInstructions) -> void:
    assert(!instructions.instructions.empty())
    self.instructions = instructions
    self.next_index = 0
    self.next_instruction = instructions.instructions[self.next_index]

func increment() -> void:
    is_finished = is_on_last_instruction
    if is_finished:
        return
    
    # Update the set of active key presses.
    if next_instruction.is_pressed:
        active_key_presses[next_instruction.input_key] = true
    else:
        active_key_presses[next_instruction.input_key] = false
    
    next_index += 1
    next_instruction = instructions.instructions[next_index] if \
            instructions.instructions.size() > next_index else null
    is_on_last_instruction = next_instruction == null

func _end_time_for_current_instruction() -> float:
    assert(!is_finished)
    return instructions.duration if is_on_last_instruction else next_instruction.time
