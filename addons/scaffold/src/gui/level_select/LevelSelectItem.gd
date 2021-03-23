tool
extends Control
class_name LevelSelectItem

signal toggled
signal pressed

const HEADER_HEIGHT := 56.0
const PADDING := Vector2(16.0, 8.0)
const FADE_TWEEN_DURATION_SEC := 0.3

export var level_id := "" setget _set_level_id,_get_level_id
export var is_open: bool setget _set_is_open,_get_is_open

var locked_header: LevelSelectItemLockedHeader
var unlocked_header: LevelSelectItemUnlockedHeader
var accordion: AccordionPanel
var body: LevelSelectItemBody

var is_new_unlocked_item := false

func _ready() -> void:
    _init_children()
    call_deferred("update")

func _process(_delta_sec: float) -> void:
    rect_min_size.y = $AccordionPanel.rect_min_size.y

func _init_children() -> void:
    locked_header = $HeaderWrapper/LevelSelectItemLockedHeader
    unlocked_header = $HeaderWrapper/LevelSelectItemUnlockedHeader
    accordion = $AccordionPanel
    body = $AccordionPanel/LevelSelectItemBody
    
    var header_size := Vector2(rect_min_size.x, HEADER_HEIGHT)
    
    $HeaderWrapper/LockedWrapper.rect_min_size = header_size
    $HeaderWrapper/LockedWrapper/HintWrapper.modulate.a = 0.0
    
    $HeaderWrapper/Header.rect_min_size = header_size
    $HeaderWrapper/Header/HBoxContainer \
            .add_constant_override("separation", PADDING.x)
    $HeaderWrapper/Header/HBoxContainer.rect_min_size = header_size
    $HeaderWrapper/Header/HBoxContainer/CaretWrapper.rect_min_size = \
            AccordionPanel.CARET_SIZE_DEFAULT * AccordionPanel.CARET_SCALE
    
    var header_style_normal := StyleBoxFlat.new()
    header_style_normal.bg_color = ScaffoldConfig.option_button_normal_color
    $HeaderWrapper/Header.add_stylebox_override("normal", header_style_normal)
    var header_style_hover := StyleBoxFlat.new()
    header_style_hover.bg_color = ScaffoldConfig.option_button_hover_color
    $HeaderWrapper/Header.add_stylebox_override("hover", header_style_hover)
    var header_style_pressed := StyleBoxFlat.new()
    header_style_pressed.bg_color = ScaffoldConfig.option_button_pressed_color
    $HeaderWrapper/Header \
            .add_stylebox_override("pressed", header_style_pressed)
    
    ScaffoldUtils.set_mouse_filter_recursively( \
            $HeaderWrapper/Header, \
            Control.MOUSE_FILTER_IGNORE)
    
    $AccordionPanel.extra_scroll_height_for_custom_header = \
            $HeaderWrapper.rect_size.y

func update() -> void:
    if level_id == "":
        return
    
    body.level_id = level_id
    
    var unlock_hint_message: String = \
            ScaffoldConfig.level_config.get_unlock_hint(level_id)
    var is_next_level_to_unlock: bool = \
            ScaffoldConfig.level_config.get_next_level_to_unlock() == level_id
    locked_header.unlock_hint_message = unlock_hint_message
    # TODO: Remove?
    var is_unlock_pulse_auto_shown := false
#    var is_unlock_pulse_auto_shown := \
#            unlock_hint_message != "" and \
#            is_next_level_to_unlock
    if is_unlock_pulse_auto_shown:
        # Finish the unlock animation for the previous item before showing the
        # unlock hint for this item.
        var delay := 0.0
#        var delay := \
#                0.0 if \
#                !SaveState.get_new_unlocked_levels().empty() else \
#                (0.3 + \
#                LOCK_LOW_PART_DELAY_SEC + \
#                LockAnimation.UNLOCK_DURATION_SEC + \
#                FADE_TWEEN_DURATION_SEC)
        Time.set_timeout(funcref(locked_header, "pulse_unlock_hint"), delay)
    
    var config: Dictionary = \
            ScaffoldConfig.level_config.get_level_config(level_id)
    var high_score: int = SaveState.get_level_high_score(level_id)
    var total_plays: int = SaveState.get_level_total_plays(level_id)
    var is_unlocked: bool = \
            SaveState.get_level_is_unlocked(level_id) and \
            !is_new_unlocked_item
    
    locked_header.is_unlocked = is_unlocked
    unlocked_header.is_unlocked = is_unlocked
    
    $HeaderWrapper/Header/HBoxContainer/LevelNumber.text = \
            str(config.number) + "."
    $HeaderWrapper/Header/HBoxContainer/LevelName.text = config.name
    
    var list_items := [
        {
            label = "High score:",
            type = LabeledControlItemType.TEXT,
            text = str(high_score),
        },
        {
            label = "Total plays:",
            type = LabeledControlItemType.TEXT,
            text = str(total_plays),
        },
    ]
    $AccordionPanel/VBoxContainer/LabeledControlList.items = list_items
    
    # TODO: Fix this. This hard-coded height assignment shouldn't be needed,
    #       but for some reason the height keeps getting enlarged otherwise.
    accordion.height_override = 268.0
    
    locked_header.update()
    unlocked_header.update()
    accordion.update()
    body.update()

func toggle() -> void:
    if Nav.get_active_screen_name() == "level_select":
        $AccordionPanel.toggle()

func unlock() -> void:
    $HeaderWrapper/LockedWrapper.visible = true
    $HeaderWrapper/LockedWrapper.modulate.a = LOCKED_OPACITY
    $HeaderWrapper/Header.visible = false
    $HeaderWrapper/Header.modulate.a = 0.0
    
    Time.set_timeout( \
            funcref($HeaderWrapper/LockedWrapper/LockAnimation, "unlock"), \
            LOCK_LOW_PART_DELAY_SEC)
    
    Time.set_timeout( \
            funcref(Audio, "play_sound"), \
            LOCK_LOW_PART_DELAY_SEC, \
            [Sound.LOCK_LOW])
    Time.set_timeout( \
            funcref(Audio, "play_sound"), \
            LOCK_LOW_PART_DELAY_SEC + LOCK_HIGH_PART_DELAY_SEC, \
            [Sound.LOCK_HIGH])

func _on_unlock_animation_finished() -> void:
    $HeaderWrapper/LockedWrapper.visible = true
    $HeaderWrapper/Header.visible = true
    var fade_tween := Tween.new()
    $HeaderWrapper/LockedWrapper.add_child(fade_tween)
    fade_tween.connect( \
            "tween_all_completed", \
            self, \
            "_on_unlock_fade_finished", \
            [fade_tween])
    fade_tween.interpolate_property( \
            $HeaderWrapper/LockedWrapper, \
            "modulate:a", \
            LOCKED_OPACITY, \
            0.0, \
            FADE_TWEEN_DURATION_SEC, \
            Tween.TRANS_QUAD, \
            Tween.EASE_IN_OUT)
    fade_tween.interpolate_property( \
            $HeaderWrapper/Header, \
            "modulate:a", \
            0.0, \
            1.0, \
            FADE_TWEEN_DURATION_SEC, \
            Tween.TRANS_QUAD, \
            Tween.EASE_IN_OUT)
    fade_tween.start()
    Time.set_timeout(funcref(Audio, "play_sound"), 0.3, [Sound.ACHIEVEMENT])

func _on_unlock_fade_finished(fade_tween: Tween) -> void:
    fade_tween.queue_free()
    $HeaderWrapper/LockedWrapper.visible = false
    $HeaderWrapper/Header.visible = true
    emit_signal("pressed")

func _set_level_id(value: String) -> void:
    level_id = value
    update()

func _get_level_id() -> String:
    return level_id

func _set_is_open(value: bool) -> void:
    $AccordionPanel.is_open = value
    update()

func _get_is_open() -> bool:
    return $AccordionPanel.is_open

func get_button() -> ShinyButton:
    return $AccordionPanel/LevelSelectItemBody.get_button()

func _on_LevelSelectItemUnlockedHeader_pressed():
    ScaffoldUtils.give_button_press_feedback()
    emit_signal("pressed")

func _on_AccordionPanel_toggled():
    emit_signal("toggled")

func _on_AccordionPanel_caret_rotated():
    $HeaderWrapper/LevelSelectItemUnlockedHeader \
            .update_caret_rotation(rotation)
