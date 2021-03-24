extends TextLabeledControlItem
class_name LevelLabeledControlItem

const LABEL := "Level:"
const DESCRIPTION := ""

var level_id: String

func _init(level_id: String).( \
        LABEL, \
        DESCRIPTION \
        ) -> void:
    self.level_id = level_id

func get_text() -> String:
    return Gs.level_config.get_level_config(level_id).name if \
            level_id != "" else \
            "—"
