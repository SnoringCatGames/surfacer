extends MarginContainer
class_name SelectionDescription

const MATCHING_SURFACE := "Selected a surface."
const MATCHING_VALID_EDGE := "A valid edge matches that selection."
const MATCHING_FAILED_EDGE := \
        "A failed edge calculation matches that selection."
const NO_MATCHING_JUMP_LAND_POSITIONS := \
        "No possible jump/land position pairs for that selection."
const NO_POSITIONS_PASSING_BROAD_PHASE := \
        "No jump/land positions passed broad-phase checks of edge " + \
        "calculation for that selection."

func set_text(text: String) -> void:
    $Label.text = text
