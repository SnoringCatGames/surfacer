class_name InstructionsPlayback
extends Reference


const EXTRA_DELAY_TO_ALLOW_COLLISION_WITH_SURFACE := 0.25

var edge: Edge
var is_additive: bool
var next_index: int
var _next_instruction: EdgeInstruction
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
    _next_instruction = \
            edge.instructions.instructions[next_index] if \
            edge.instructions.instructions.size() > next_index else \
            null
    is_on_last_instruction = _next_instruction == null
    is_finished = is_on_last_instruction
    active_key_presses = {}
    _next_active_key_presses = {}


func update(
        scaled_time: float,
        character) -> Array:
    previous_time_scaled = current_time_scaled
    current_time_scaled = scaled_time
    
    active_key_presses = _next_active_key_presses.duplicate()
    
    var new_instructions := []
    
    while !is_finished and \
            _get_start_time_scaled_for_next_instruction() <= scaled_time:
        if !is_on_last_instruction:
            _ensure_facing_correct_direction_before_update(
                    new_instructions,
                    character)
            
            new_instructions.push_back(_next_instruction)
        
        _increment()
    
    _ensure_facing_correct_direction_after_update(
            new_instructions,
            character)
    
    return new_instructions


func _increment() -> void:
    is_finished = is_on_last_instruction
    if is_finished:
        return
    
    # Update the set of active key presses.
    if _next_instruction.is_pressed:
        _next_active_key_presses[_next_instruction.input_key] = true
        active_key_presses[_next_instruction.input_key] = true
    else:
        _next_active_key_presses[_next_instruction.input_key] = false
        active_key_presses[_next_instruction.input_key] = \
                true if \
                is_additive and \
                active_key_presses.has(_next_instruction.input_key) and \
                active_key_presses[_next_instruction.input_key] else \
                false
    
    next_index += 1
    _next_instruction = \
            edge.instructions.instructions[next_index] if \
            edge.instructions.instructions.size() > next_index else \
            null
    is_on_last_instruction = _next_instruction == null


func get_previous_elapsed_time_scaled() -> float:
    return previous_time_scaled - start_time_scaled


func get_elapsed_time_scaled() -> float:
    return Sc.time.get_scaled_play_time() - start_time_scaled


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
        duration_until_next_instruction = _next_instruction.time
    
    return start_time_scaled + duration_until_next_instruction


func _ensure_facing_correct_direction_before_update(
        new_instructions: Array,
        character) -> void:
    if character.movement_params \
            .always_tries_to_face_direction_of_motion and \
            next_index == 0 and \
            character.velocity.x != 0 and \
            (character.velocity.x < 0) != \
                    (character.surface_state.horizontal_facing_sign < 0):
        # At the start of edge playback, turn the character to face the
        # initial direction they're moving in.
        var turn_around_instruction := \
                _create_instruction_to_face_direction_of_movement(
                        0.0,
                        character)
        new_instructions.push_back(turn_around_instruction)


func _ensure_facing_correct_direction_after_update(
        new_instructions: Array,
        character) -> void:
    var just_released_move_sideways := false
    var is_facing_left := false
    
    for instruction in new_instructions:
        match instruction.input_key:
            "ml":
                is_facing_left = true
                just_released_move_sideways = !instruction.is_pressed
            "mr":
                is_facing_left = false
                just_released_move_sideways = !instruction.is_pressed
            "fl":
                is_facing_left = true
            "fr":
                is_facing_left = false
            _:
                pass
    
    if character.movement_params.always_tries_to_face_direction_of_motion and \
            just_released_move_sideways and \
            character.velocity.x != 0 and \
            character.velocity.x < 0 != is_facing_left:
        # Turn the character around, so they are facing the direction they're
        # moving in.
        var turn_around_instruction := \
                _create_instruction_to_face_direction_of_movement(
                        new_instructions.back().time,
                        character)
        new_instructions.push_back(turn_around_instruction)


func _create_instruction_to_face_direction_of_movement(
        time: float,
        character) -> EdgeInstruction:
    var input_key := \
            "fl" if \
            character.velocity.x < 0 else \
            "fr"
    
    _next_active_key_presses[input_key] = true
    active_key_presses[input_key] = true
    
    return EdgeInstruction.new(input_key, time, true)
