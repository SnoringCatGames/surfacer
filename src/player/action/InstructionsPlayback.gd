class_name InstructionsPlayback
extends Reference

const EXTRA_DELAY_TO_ALLOW_COLLISION_WITH_SURFACE := 0.25

var edge: Edge
var is_additive: bool
var next_index: int
var next_instruction: EdgeInstruction
var start_time_scaled: float
var previous_time_scaled: float
var current_time_scaled: float
var is_finished: bool
var is_on_last_instruction: bool
# Dictionary<String, boolean>
var active_key_presses: Dictionary
# Dictionary<String, boolean>
var _next_active_key_presses: Dictionary


func _init(
        edge: Edge,
        is_additive: bool) -> void:
    self.edge = edge
    self.is_additive = is_additive


func start(scaled_time: float) -> void:
    start_time_scaled = scaled_time
    previous_time_scaled = scaled_time
    current_time_scaled = scaled_time
    next_index = 0
    next_instruction = \
            edge.instructions.instructions[next_index] if \
            edge.instructions.instructions.size() > next_index else \
            null
    is_on_last_instruction = next_instruction == null
    is_finished = is_on_last_instruction
    active_key_presses = {}
    _next_active_key_presses = {}


func update(
        scaled_time: float,
        navigation_state: PlayerNavigationState) -> Array:
    # TODO: If we don't ever need more complicated dynamic instruction updates
    #       based on navigation state, then remove that param.
    
    previous_time_scaled = current_time_scaled
    current_time_scaled = scaled_time
    
    active_key_presses = _next_active_key_presses.duplicate()
    
    var new_instructions := []
    while !is_finished and \
            _get_start_time_scaled_for_next_instruction() <= \
                    scaled_time:
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
    next_instruction = \
            edge.instructions.instructions[next_index] if \
            edge.instructions.instructions.size() > next_index else \
            null
    is_on_last_instruction = next_instruction == null


func get_previous_elapsed_time_scaled() -> float:
    return previous_time_scaled - start_time_scaled


func get_elapsed_time_scaled() -> float:
    return Gs.time.get_scaled_play_time() - start_time_scaled


func _get_start_time_scaled_for_next_instruction() -> float:
    assert(!is_finished)
    
    var duration_until_next_instruction: float
    if is_on_last_instruction:
        duration_until_next_instruction = edge.instructions.duration
        if edge.get_should_end_by_colliding_with_surface():
            # With slight movement error it's possible for the edge duration to
            # elapse before actually landing on the destination surface. So
            # this should allow for a little extra time at the end in order to
            # end by landing on the surface.
            duration_until_next_instruction += \
                    EXTRA_DELAY_TO_ALLOW_COLLISION_WITH_SURFACE
    else:
        duration_until_next_instruction = next_instruction.time
    
    return start_time_scaled + duration_until_next_instruction
