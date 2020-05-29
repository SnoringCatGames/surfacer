extends LegendItem
class_name InstructionStartLegendItem

const TYPE := LegendItemType.INSTRUCTION_START
const TEXT := "Instruction\nstart"

const SCALE := 0.7

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape(
        center: Vector2, \
        size: Vector2) -> void:
    DrawUtils.draw_instruction_indicator( \
            self, \
            "move_right", \
            true, \
            center, \
            DrawUtils.EDGE_INSTRUCTION_INDICATOR_LENGTH * SCALE, \
            AnnotationElementDefaults.INSTRUCTION_COLOR_PARAMS.get_color())
