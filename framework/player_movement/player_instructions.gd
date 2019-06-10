extends Reference
class_name PlayerInstructions

# Array<PlayerInstruction>
var instructions: Array
var duration: int
var distance: float

# For annotation debugging.
# Array<Vector2>
var frame_positions: PoolVector2Array
# Array<Vector2>
var constraint_positions: PoolVector2Array

# Instructions don't need to be pre-sorted.
func _init(instructions: Array, duration: int, distance: float, frame_positions: Array, \
        constraint_positions: Array) -> void:
    self.instructions = instructions
    self.duration = duration
    self.distance = distance
    self.frame_positions = PoolVector2Array(frame_positions)
    self.constraint_positions = PoolVector2Array(constraint_positions)
    
    self.instructions.sort_custom(self, "instruction_comparator")

# Inserts the given instruction in sorted order.
# TODO: Remove?
func insert(instruction: PlayerInstruction) -> int:
    var index := instructions.bsearch_custom(instruction, self, "instruction_comparator")
    instructions.insert(index, instruction)
    return index

# Removes the given instruction if it exists.
# TODO: Remove?
func remove(instruction: PlayerInstruction) -> bool:
    var index := instructions.bsearch_custom(instruction, self, "instruction_comparator")
    if instructions[index] == instruction:
        instructions.remove(index)
        return true
    else:
        return false

# This will mutate the time field on the given PlayerInstruction.
# TODO: Remove?
func is_instruction_in_range( \
        instruction: PlayerInstruction, min_time: float, max_time: float) -> bool:
    var instruction_count := instructions.size()
    var possible_match: PlayerInstruction
    instruction.time = min_time
    var index := instructions.bsearch_custom(instruction, self, "instruction_comparator")
    
    if index >= instruction_count:
        return false
    possible_match = instructions[index]
    
    # Make sure that we don't consider a possible match if it's time is less than min_time.
    if possible_match.time < min_time:
        index += 1
        if index >= instruction_count:
            return false
        possible_match = instructions[index]
    
    while possible_match.time <= max_time:
        if instruction.input_key == possible_match.input_key and \
                instruction.is_pressed == possible_match.is_pressed and \
                instruction.position == possible_match.position:
            return true
        
        index += 1
        if index >= instruction_count:
            return false
        possible_match = instructions[index]
    
    return false

static func instruction_comparator(a: PlayerInstruction, b: PlayerInstruction) -> bool:
    return a.time < b.time
