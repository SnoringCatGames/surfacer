extends Reference
class_name EdgeInstructions

# Array<EdgeInstruction>
var instructions: Array

var duration: float

# Instructions don't need to be pre-sorted.
func _init( \
        instructions: Array, \
        duration: float) -> void:
    self.instructions = instructions
    self.duration = duration
    
    self.instructions.sort_custom( \
            self, \
            "instruction_comparator")

# Inserts the given instruction in sorted order.
# TODO: Remove?
func insert(instruction: EdgeInstruction) -> int:
    var index := instructions.bsearch_custom( \
            instruction, \
            self, \
            "instruction_comparator")
    instructions.insert(index, instruction)
    return index

# Removes the given instruction if it exists.
# TODO: Remove?
func remove(instruction: EdgeInstruction) -> bool:
    var index := instructions.bsearch_custom( \
            instruction, \
            self, \
            "instruction_comparator")
    if instructions[index] == instruction:
        instructions.remove(index)
        return true
    else:
        return false

# This will mutate the time field on the given EdgeInstruction.
# TODO: Remove?
func is_instruction_in_range( \
        instruction: EdgeInstruction, \
        min_time: float, \
        max_time: float) -> bool:
    var instruction_count := instructions.size()
    var possible_match: EdgeInstruction
    instruction.time = min_time
    var index := instructions.bsearch_custom( \
            instruction, \
            self, \
            "instruction_comparator")
    
    if index >= instruction_count:
        return false
    possible_match = instructions[index]
    
    # Make sure that we don't consider a possible match if it's time is less
    # than min_time.
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

static func instruction_comparator( \
        a: EdgeInstruction, \
        b: EdgeInstruction) -> bool:
    return a.time < b.time

func to_string() -> String:
    var instructions_str := ""
    for instruction in instructions:
        instructions_str += instruction.to_string()
    return "EdgeInstructions{ instructions: [ %s ] }" % instructions_str

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
    
    var format_string_template := "EdgeInstructions{ instructions: [ " + \
            "%s" + \
            "\n%s] }"
    var format_string_arguments := [ \
            instructions_str, \
            indent_level_str, \
        ]
    return format_string_template % format_string_arguments
