# Information for how to move from a start position to an end position.
extends Reference
class_name Edge

var instructions: MovementInstructions

var weight: float setget ,_get_weight

func _init(instructions: MovementInstructions) -> void:
    self.instructions = instructions

func _get_weight() -> float:
    return instructions.distance_squared

func _get_class_name() -> String:
    Utils.error("Abstract Edge._get_class_name is not implemented")
    return ""

func _get_start_string() -> String:
    Utils.error("Abstract Edge._get_start_string is not implemented")
    return ""

func _get_end_string() -> String:
    Utils.error("Abstract Edge._get_end_string is not implemented")
    return ""

func to_string() -> String:
    var format_string_template := "%s{ start: %s, end: %s, instructions: %s }"
    var format_string_arguments := [ \
            _get_class_name(), \
            _get_start_string(), \
            _get_end_string(), \
            instructions.to_string(), \
        ]
    return format_string_template % format_string_arguments

func to_string_with_newlines(indent_level: int) -> String:
    var indent_level_str := ""
    for i in range(indent_level):
        indent_level_str += "\t"
    
    var format_string_template := "%s{" + \
            "\n\t%sstart: %s," + \
            "\n\t%send: %s," + \
            "\n\t%sinstructions: %s," + \
        "\n%s}"
    var format_string_arguments := [ \
            _get_class_name(), \
            indent_level_str, \
            _get_start_string(), \
            indent_level_str, \
            _get_end_string(), \
            indent_level_str, \
            instructions.to_string_with_newlines(indent_level + 1), \
            indent_level_str, \
        ]
    
    return format_string_template % format_string_arguments
