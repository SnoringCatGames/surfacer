extends LegendItem
class_name InstructionEndLegendItem

const TYPE := LegendItemType.INSTRUCTION_END
const TEXT := "Instruction\nend"

const SCALE := 0.7

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape( \
        center: Vector2, \
        size: Vector2) -> void:
    Gs.draw_utils.draw_instruction_indicator( \
            self, \
            "move_right", \
            false, \
            center, \
            SurfacerDrawUtils.EDGE_INSTRUCTION_INDICATOR_LENGTH * SCALE, \
            AnnotationElementDefaults.DEFAULT_INSTRUCTION_COLOR_PARAMS \
                    .get_color())
