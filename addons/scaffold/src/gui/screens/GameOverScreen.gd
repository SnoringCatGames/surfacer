tool
extends Screen
class_name GameOverScreen

const NAME := "game_over"
const LAYER_NAME := "menu_screen"
const AUTO_ADAPTS_GUI_SCALE := true
const INCLUDES_STANDARD_HIERARCHY := true
const INCLUDES_NAV_BAR := false
const INCLUDES_CENTER_CONTAINER := true

var level_id: String
var score: String
var high_score: String
var time: String
var reached_new_high_score: bool
var new_unlocked_levels: Array

func _init().( \
        NAME, \
        LAYER_NAME, \
        AUTO_ADAPTS_GUI_SCALE, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    pass

func _ready() -> void:
    _update_stats()

func _on_activated() -> void:
    ._on_activated()
    Gs.audio.play_music(Gs.game_over_music)
    _update_stats()

func _get_focused_button() -> ShinyButton:
    return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
            CenterContainer/VBoxContainer/VBoxContainer/ \
            SelectLevelButton as ShinyButton

func _update_stats() -> void:
    var unlocked_new_level_label := $FullScreenPanel/VBoxContainer/ \
            CenteredPanel/ScrollContainer/CenterContainer/VBoxContainer/ \
            VBoxContainer2/UnlockedNewLevelLabel
    var high_score_label := $FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/VBoxContainer2/ \
            HighScoreLabel
    var control_list := $FullScreenPanel/VBoxContainer/CenteredPanel/ \
            ScrollContainer/CenterContainer/VBoxContainer/AccordionPanel/ \
            LabeledControlList
    
    unlocked_new_level_label.visible = !new_unlocked_levels.empty()
    
    high_score_label.visible = \
            Gs.uses_level_scores and reached_new_high_score
    
    control_list.items = []
    control_list.items.push_back({
        label = "Level:",
        type = LabeledControlItemType.TEXT,
        text = level_id,
    })
    if Gs.uses_level_scores:
        control_list.items.push_back({
            label = "Score:",
            type = LabeledControlItemType.TEXT,
            text = score,
        })
        control_list.items.push_back({
            label = "High score:",
            type = LabeledControlItemType.TEXT,
            text = high_score,
        })
    control_list.items.push_back({
        label = "Time:",
        type = LabeledControlItemType.TEXT,
        text = time,
    })

func _on_SelectLevelButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.audio.play_music(Gs.main_menu_music)
    Gs.nav.open("level_select")

func _on_HomeButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.audio.play_music(Gs.main_menu_music)
    Gs.nav.open("main_menu")

func _on_RetryButton_pressed():
    Gs.utils.give_button_press_feedback(true)
    Gs.nav.open("game", true)
    Gs.nav.screens["game"].start_level(level_id)
