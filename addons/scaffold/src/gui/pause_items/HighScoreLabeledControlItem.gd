class_name HighScoreLabeledControlItem
extends TextLabeledControlItem

const LABEL := "High score:"
const DESCRIPTION := ""

var level_id: String

func _init(level_or_id).( \
        LABEL, \
        DESCRIPTION \
        ) -> void:
    self.level_id = \
            level_or_id.level_id if \
            level_or_id is ScaffoldLevel else \
            (level_or_id if \
            level_or_id is String else \
            "")

func get_text() -> String:
    return str(Gs.save_state.get_level_high_score(level_id)) if \
            level_id != "" else \
            "—"
