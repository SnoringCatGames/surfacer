class_name InstructionStartLegendItem
extends LegendItem


const TYPE := "INSTRUCTION_START"
const TEXT := "Instruction\nstart"

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
            true,
            center,
            Sc.ann_params.edge_instruction_indicator_length * SCALE,
            Sc.ann_params.default_instruction_color_params.get_color())
