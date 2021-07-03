class_name InstructionEndLegendItem
extends LegendItem


const TYPE := LegendItemType.INSTRUCTION_END
const TEXT := "Instruction\nend"

const SCALE := 0.7


func _init().(
        TYPE,
        TEXT) -> void:
    pass


func _draw_shape(
        center: Vector2,
        size: Vector2) -> void:
    Gs.draw.draw_instruction_indicator(
            self,
            "mr",
            false,
            center,
            SurfacerDrawUtils.EDGE_INSTRUCTION_INDICATOR_LENGTH * SCALE,
            Surfacer.ann_defaults.DEFAULT_INSTRUCTION_COLOR_PARAMS \
                    .get_color())
