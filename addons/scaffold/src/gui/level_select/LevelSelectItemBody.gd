extends Node
class_name LevelSelectItemBody

var level_id: String

func update() -> void:
    var list_items := []
    if Gs.uses_level_scores:
        list_items.push_back(HighScoreLabeledControlItem.new(level_id))
    list_items.push_back(TotalPlaysLabeledControlItem.new(level_id))
    $LabeledControlList.items = list_items

func get_button() -> ShinyButton:
    return $PlayButton as ShinyButton

func _on_PlayButton_pressed():
    Gs.utils.give_button_press_feedback(true)
    Gs.nav.open("game", true)
    Gs.nav.screens["game"].start_level(level_id)
