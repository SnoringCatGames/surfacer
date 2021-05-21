class_name EdgeInstructions
extends Reference

# Array<EdgeInstruction>
var instructions: Array

var duration: float

# Instructions don't need to be pre-sorted.
func _init(
        instructions := [],
        duration := INF) -> void:
    self.instructions = instructions
    self.duration = duration
    self.instructions.sort_custom(
            self,
            "instruction_comparator")

# Inserts the given instruction in sorted order.
# TODO: Remove?
func insert(instruction: EdgeInstruction) -> int:
    var index := instructions.bsearch_custom(
            instruction,
            self,
            "instruction_comparator")
    instructions.insert(index, instruction)
    return index

# Removes the given instruction if it exists.
# TODO: Remove?
func remove(instruction: EdgeInstruction) -> bool:
    var index := instructions.bsearch_custom(
            instruction,
            self,
            "instruction_comparator")
    if instructions[index] == instruction:
        instructions.remove(index)
        return true
    else:
        return false

# This will mutate the time field on the given EdgeInstruction.
# TODO: Remove?
func is_instruction_in_range(
        instruction: EdgeInstruction,
        min_time: float,
        max_time: float) -> bool:
    var instruction_count := instructions.size()
    var possible_match: EdgeInstruction
    instruction.time = min_time
    var index := instructions.bsearch_custom(
            instruction,
            self,
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

func get_is_facing_left_at_time(
        time: float,
        starts_facing_left := false) -> bool:
    var is_facing_left := starts_facing_left
    for instruction in instructions:
        if instruction.time > time:
            break
        match instruction.input_key:
            "ml", \
            "fl":
                is_facing_left = true
            "mr", \
            "fr":
                is_facing_left = false
            "j", \
            "mu", \
            "md", \
            "gw":
                # This input does not affect the direction the player faces.
                pass
            _:
                Utils.error()
    return is_facing_left

static func instruction_comparator(
        a: EdgeInstruction,
        b: EdgeInstruction) -> bool:
    return a.time < b.time

func to_string() -> String:
    var instructions_str := ""
    for instruction in instructions:
        instructions_str += instruction.to_string()
    return "EdgeInstructions{ instructions: [ %s ] }" % instructions_str

func to_string_with_newlines(indent_level := 0) -> String:
    var indent_level_str := ""
    for i in indent_level:
        indent_level_str += "\t"
    
    var instructions_str := ""
    for instruction in instructions:
        instructions_str += "\n\t%s%s," % [
                indent_level_str,
                instruction.to_string(),
            ]
    
    var format_string_template := (\
            "EdgeInstructions{ instructions: [ " +
            "%s" +
            "\n%s] }")
    var format_string_arguments := [
            instructions_str,
            indent_level_str,
        ]
    return format_string_template % format_string_arguments

func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    instructions = _load_instructions_json_array(json_object.i, context)
    duration = json_object.d if json_object.d != -1 else INF

func _load_instructions_json_array(
        json_object: Array,
        context: Dictionary) -> Array:
    var result := []
    result.resize(json_object.size())
    for i in json_object.size():
        var instruction := EdgeInstruction.new()
        instruction.load_from_json_object(json_object[i], context)
        result[i] = instruction
    return result

func to_json_object() -> Dictionary:
    return {
        i = _get_instructions_json_array(),
        d = duration if duration != INF else -1,
    }

func _get_instructions_json_array() -> Array:
    var result := []
    result.resize(instructions.size())
    for i in instructions.size():
        result[i] = instructions[i].to_json_object()
    return result
