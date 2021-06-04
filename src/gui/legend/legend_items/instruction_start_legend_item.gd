class_name InstructionStartLegendItem
extends LegendItem


const TYPE := LegendItemType.INSTRUCTION_START
const TEXT := "Instruction\nstart"

const SCALE := 0.7


func _init().(
        TYPE,
        TEXT) -> void:
    pass


func _draw_shape(
        center: Vector2,
        size: Vector2) -> void:
    Gs.draw_utils.draw_instruction_indicator(
            self,
            "mr",
            true,
            center,
            SurfacerDrawUtils.EDGE_INSTRUCTION_INDICATOR_LENGTH * SCALE,
            Surfacer.ann_defaults.DEFAULT_INSTRUCTION_COLOR_PARAMS \
                    .get_color())
