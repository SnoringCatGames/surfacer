extends Reference
class_name InstructionsPlayback

var edge: Edge
var is_additive: bool
var next_index: int
var next_instruction: MovementInstruction
var start_time: float
var is_finished: bool
var is_on_last_instruction: bool
# Dictionary<String, boolean>
var active_key_presses: Dictionary
# Dictionary<String, boolean>
var _next_active_key_presses: Dictionary

func _init(edge: Edge, is_additive: bool) -> void:
    assert(!edge.instructions.instructions.empty())
    self.edge = edge
    self.is_additive = is_additive

func start(time_sec: float) -> void:
    start_time = time_sec
    next_index = 0
    next_instruction = edge.instructions.instructions[next_index]
    is_finished = false
    is_on_last_instruction = false
    active_key_presses = {}
    _next_active_key_presses = {}

func update(time_sec: float, navigation_state: PlayerNavigationState) -> Array:
    # TODO: If we don't ever need more complicated dynamic instruction updates based on navigation
    #       state, then remove that param.
    
    active_key_presses = _next_active_key_presses.duplicate()
    
    var new_instructions := []
    while !is_finished and _get_end_time_for_current_instruction() <= time_sec:
        if !is_on_last_instruction:
            new_instructions.push_back(next_instruction)
        increment()
    return new_instructions

func increment() -> void:
    is_finished = is_on_last_instruction
    if is_finished:
        return
    
    # Update the set of active key presses.
    if next_instruction.is_pressed:
        _next_active_key_presses[next_instruction.input_key] = true
        active_key_presses[next_instruction.input_key] = true
    else:
        _next_active_key_presses[next_instruction.input_key] = false
        active_key_presses[next_instruction.input_key] = \
                true if \
                is_additive and \
                active_key_presses.has(next_instruction.input_key) and \
                active_key_presses[next_instruction.input_key] else \
                false
    
    next_index += 1
    next_instruction = edge.instructions.instructions[next_index] if \
            edge.instructions.instructions.size() > next_index else null
    is_on_last_instruction = next_instruction == null

func _get_end_time_for_current_instruction() -> float:
    assert(!is_finished)
    return start_time + \
            (edge.instructions.duration if is_on_last_instruction else next_instruction.time)
