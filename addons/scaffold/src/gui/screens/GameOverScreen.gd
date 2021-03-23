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
    Gs.audio.play_music(Music.GAME_OVER_MUSIC_TYPE)
    _update_stats()

func _get_focused_button() -> ShinyButton:
    # Conditionally suggest retry, if the player didn't finish the level.
    if finished_level:
        return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
                CenterContainer/VBoxContainer/VBoxContainer/ \
                SelectLevelButton as ShinyButton
    else:
        return $FullScreenPanel/VBoxContainer/CenteredPanel/ScrollContainer/ \
                CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/ \
                RetryButton as ShinyButton

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
    
    high_score_label.visible = reached_new_high_score
    
    control_list.items = [
        {
            label = "Level:",
            type = LabeledControlItemType.TEXT,
            text = level_id,
        },
        {
            label = "Score:",
            type = LabeledControlItemType.TEXT,
            text = score,
        },
        {
            label = "High score:",
            type = LabeledControlItemType.TEXT,
            text = high_score,
        },
        {
            label = "Time:",
            type = LabeledControlItemType.TEXT,
            text = time,
        },
    ]

func _on_SelectLevelButton_pressed():
    Global.give_button_press_feedback()
    Gs.audio.play_music(Music.MAIN_MENU_MUSIC_TYPE)
    Gs.nav.open(ScreenType.LEVEL_SELECT)

func _on_HomeButton_pressed():
    Global.give_button_press_feedback()
    Gs.audio.play_music(Music.MAIN_MENU_MUSIC_TYPE)
    Gs.nav.open(ScreenType.MAIN_MENU)

func _on_RetryButton_pressed():
    Global.give_button_press_feedback(true)
    Gs.nav.open(ScreenType.GAME, true)
    Gs.nav.screens[ScreenType.GAME].start_level(level_id)
