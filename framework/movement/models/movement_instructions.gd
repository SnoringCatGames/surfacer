extends Reference
class_name MovementInstructions

# Array<MovementInstruction>
var instructions: Array

var duration: float

var distance_squared: float

# The positions of each frame of movement according to the discrete per-frame movement
# calculations of the instruction test. This is used for annotation debugging.
var frame_discrete_positions_from_test: PoolVector2Array

# The positions of each frame of movement according to the continous per-frame movement
# calculations of the underlying horizontal step calculations.
var frame_continous_positions_from_steps: PoolVector2Array

# The end positions of each MovementCalcStep. These correspond to intermediate-surface constraints
# and the destination position. This is used for annotation debugging.
var constraint_positions: PoolVector2Array

var horizontal_instruction_start_positions: PoolVector2Array

var horizontal_instruction_end_positions: PoolVector2Array

var jump_instruction_end_position: Vector2

# Instructions don't need to be pre-sorted.
func _init(instructions: Array, duration: float, distance_squared: float, \
        constraint_positions := []) -> void:
    self.instructions = instructions
    self.duration = duration
    self.distance_squared = distance_squared
    self.constraint_positions = PoolVector2Array(constraint_positions)
    
    self.instructions.sort_custom(self, "instruction_comparator")

# Inserts the given instruction in sorted order.
# TODO: Remove?
func insert(instruction: MovementInstruction) -> int:
    var index := instructions.bsearch_custom(instruction, self, "instruction_comparator")
    instructions.insert(index, instruction)
    return index

# Removes the given instruction if it exists.
# TODO: Remove?
func remove(instruction: MovementInstruction) -> bool:
    var index := instructions.bsearch_custom(instruction, self, "instruction_comparator")
    if instructions[index] == instruction:
        instructions.remove(index)
        return true
    else:
        return false

# This will mutate the time field on the given MovementInstruction.
# TODO: Remove?
func is_instruction_in_range( \
        instruction: MovementInstruction, min_time: float, max_time: float) -> bool:
    var instruction_count := instructions.size()
    var possible_match: MovementInstruction
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

static func instruction_comparator(a: MovementInstruction, b: MovementInstruction) -> bool:
    return a.time < b.time

func to_string() -> String:
    var instructions_str := ""
    for instruction in instructions:
        instructions_str += instruction.to_string()
    return "MovementInstructions{ instructions: [ %s ] }" % instructions_str

func to_string_with_newlines(indent_level := 0) -> String:
    var indent_level_str := ""
    for i in range(indent_level):
        indent_level_str += "\t"
    
    var instructions_str := ""
    for instruction in instructions:
        instructions_str += "\n\t%s%s," % [ \
                indent_level_str, \
                instruction.to_string(), \
            ]
    
    var format_string_template := "MovementInstructions{ instructions: [ " + \
            "%s" + \
            "\n%s] }"
    var format_string_arguments := [ \
            instructions_str, \
            indent_level_str, \
        ]
    return format_string_template % format_string_arguments
