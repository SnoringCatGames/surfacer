class_name InstructionEndLegendItem
extends LegendItem


const TYPE := "INSTRUCTION_END"
const TEXT := "Instruction\nend"

const SCALE := 0.7


func _init().(
        TYPE,
        TEXT) -> void:
    pass


func _draw_shape(
        center: Vector2,
        size: Vector2) -> void:
    Sc.draw.draw_instruction_indicator(
            self,
            "mr",
            false,
            center,
            Sc.annotators.params.edge_instruction_indicator_length * SCALE,
            Sc.palette.get_color("default_instruction_color"))
