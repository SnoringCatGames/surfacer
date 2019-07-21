extends Reference
class_name InstructionsPlayback

var instructions: PlayerInstructions
var next_index := 0
var next_instruction: PlayerInstruction
var is_finished := false
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
    is_finished = next_instruction == null
