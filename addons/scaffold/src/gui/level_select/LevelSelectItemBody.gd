extends Node
class_name LevelSelectItemBody

var level_id: String

func update() -> void:
    var high_score: int = Gs.save_state.get_level_high_score(level_id)
    var total_plays: int = Gs.save_state.get_level_total_plays(level_id)
    
    var list_items := []
    if Gs.uses_level_scores:
        list_items.push_back({
            label = "High score:",
            type = LabeledControlItemType.TEXT,
            text = str(high_score),
        })
    list_items.push_back({
        label = "Total plays:",
        type = LabeledControlItemType.TEXT,
        text = str(total_plays),
    })
    $LabeledControlList.items = list_items

func get_button() -> ShinyButton:
    return $PlayButton as ShinyButton

func _on_PlayButton_pressed():
    Gs.utils.give_button_press_feedback(true)
    Gs.nav.open("game", true)
    Gs.nav.screens["game"].start_level(level_id)
