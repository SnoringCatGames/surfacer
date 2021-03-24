class_name TimeLabeledControlItem
extends TextLabeledControlItem

const LABEL := "Time:"
const DESCRIPTION := ""

func _init(__ = null).( \
        LABEL, \
        DESCRIPTION \
        ) -> void:
    pass

func get_text() -> String:
    return Gs.utils.get_time_string_from_seconds( \
            Gs.time.elapsed_play_time_actual_sec - \
            Gs.level.level_start_time) if \
            is_instance_valid(Gs.level) else \
            "—"
