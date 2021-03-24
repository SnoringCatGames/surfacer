extends TextLabeledControlItem
class_name HighScoreLabeledControlItem

const LABEL := "High score:"
const DESCRIPTION := ""

var level_id: String

func _init(level_id: String).( \
        LABEL, \
        DESCRIPTION \
        ) -> void:
    self.level_id = level_id

func get_text() -> String:
    return str(Gs.save_state.get_level_high_score(level_id)) if \
            level_id != "" else \
            "—"
