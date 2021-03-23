tool
extends Control
class_name LevelSelectItem

signal toggled
signal pressed

const HEADER_HEIGHT := 56.0
const PADDING := Vector2(16.0, 8.0)
const LOCKED_OPACITY := 0.6
const FADE_TWEEN_DURATION_SEC := 0.3
const LOCK_LOW_PART_DELAY_SEC := 0.4
const LOCK_HIGH_PART_DELAY_SEC := 0.15
const HINT_PULSE_DURATION_SEC := 2.0

export var level_id := "" setget _set_level_id,_get_level_id
export var is_open: bool setget _set_is_open,_get_is_open

var is_new_unlocked_item := false

var hint_tween: Tween

func _enter_tree() -> void:
    hint_tween = Tween.new()
    $HeaderWrapper/LockedWrapper/HintWrapper/Hint.add_child(hint_tween)

func _ready() -> void:
    _init_children()
    call_deferred("update")

func _process(_delta_sec: float) -> void:
    rect_min_size.y = $AccordionPanel.rect_min_size.y

func _init_children() -> void:
    var header_size := Vector2(rect_min_size.x, HEADER_HEIGHT)
    
    $HeaderWrapper/LockedWrapper.rect_min_size = header_size
    $HeaderWrapper/LockedWrapper/HintWrapper.modulate.a = 0.0
    
    $HeaderWrapper/Header.rect_min_size = header_size
    $HeaderWrapper/Header.connect("pressed", self, "_on_header_pressed")
    $HeaderWrapper/Header/HBoxContainer \
            .add_constant_override("separation", PADDING.x)
    $HeaderWrapper/Header/HBoxContainer.rect_min_size = header_size
    $HeaderWrapper/Header/HBoxContainer/CaretWrapper.rect_min_size = \
            AccordionPanel.CARET_SIZE_DEFAULT * AccordionPanel.CARET_SCALE
    
    var header_style_normal := StyleBoxFlat.new()
    header_style_normal.bg_color = Constants.OPTION_BUTTON_COLOR_NORMAL
    $HeaderWrapper/Header.add_stylebox_override("normal", header_style_normal)
    var header_style_hover := StyleBoxFlat.new()
    header_style_hover.bg_color = Constants.OPTION_BUTTON_COLOR_HOVER
    $HeaderWrapper/Header.add_stylebox_override("hover", header_style_hover)
    var header_style_pressed := StyleBoxFlat.new()
    header_style_pressed.bg_color = Constants.OPTION_BUTTON_COLOR_PRESSED
    $HeaderWrapper/Header \
            .add_stylebox_override("pressed", header_style_pressed)
    
    Gs.utils.set_mouse_filter_recursively( \
            $HeaderWrapper/Header, \
            Control.MOUSE_FILTER_IGNORE)
    
    $AccordionPanel.extra_scroll_height_for_custom_header = \
            $HeaderWrapper.rect_size.y
    $AccordionPanel.connect("caret_rotated", self, "_on_caret_rotated")
    $AccordionPanel.connect("toggled", self, "_on_accordion_toggled")

func update() -> void:
    if level_id == "":
        return
    
    var unlock_hint_message := LevelConfig.get_unlock_hint(level_id)
    var is_next_level_to_unlock := \
            LevelConfig.get_next_level_to_unlock() == level_id
    $HeaderWrapper/LockedWrapper/HintWrapper/Hint.text = unlock_hint_message
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
#                !Gs.save_state.get_new_unlocked_levels().empty() else \
#                (0.3 + \
#                LOCK_LOW_PART_DELAY_SEC + \
#                LockAnimation.UNLOCK_DURATION_SEC + \
#                FADE_TWEEN_DURATION_SEC)
        Gs.time.set_timeout(funcref(self, "_pulse_unlock_hint"), delay)
    
    var config := LevelConfig.get_level_config(level_id)
    var high_score := Gs.save_state.get_level_high_score(level_id)
    var has_finished := Gs.save_state.get_level_has_finished(level_id)
    var total_plays := Gs.save_state.get_level_total_plays(level_id)
    var is_unlocked := \
            Gs.save_state.get_level_is_unlocked(level_id) and \
            !is_new_unlocked_item
    
    $HeaderWrapper/LockedWrapper.visible = !is_unlocked
    $HeaderWrapper/LockedWrapper.modulate.a = LOCKED_OPACITY
    
    $HeaderWrapper/Header.visible = is_unlocked
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
    $AccordionPanel.height_override = 268.0
    
    $AccordionPanel.update()

func toggle() -> void:
    if Gs.nav.get_active_screen_type() == ScreenType.LEVEL_SELECT:
        $AccordionPanel.toggle()

func unlock() -> void:
    $HeaderWrapper/LockedWrapper.visible = true
    $HeaderWrapper/LockedWrapper.modulate.a = LOCKED_OPACITY
    $HeaderWrapper/Header.visible = false
    $HeaderWrapper/Header.modulate.a = 0.0
    $HeaderWrapper/LockedWrapper/LockAnimation.connect( \
            "unlock_finished", \
            self, \
            "_on_unlock_animation_finished")
    
    Gs.time.set_timeout( \
            funcref($HeaderWrapper/LockedWrapper/LockAnimation, "unlock"), \
            LOCK_LOW_PART_DELAY_SEC)
    
    Gs.time.set_timeout( \
            funcref(Audio, "play_sound"), \
            LOCK_LOW_PART_DELAY_SEC, \
            [Sound.LOCK_LOW])
    Gs.time.set_timeout( \
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
    Gs.time.set_timeout(funcref(Audio, "play_sound"), 0.3, [Sound.ACHIEVEMENT])

func _on_unlock_fade_finished(fade_tween: Tween) -> void:
    fade_tween.queue_free()
    $HeaderWrapper/LockedWrapper.visible = false
    $HeaderWrapper/Header.visible = true
    emit_signal("pressed")

func _pulse_unlock_hint() -> void:
    hint_tween.stop_all()
    var fade_in_duration_sec := 0.3
    hint_tween.interpolate_property( \
            $HeaderWrapper/LockedWrapper/HintWrapper, \
            "modulate:a", \
            0.0, \
            1.0, \
            fade_in_duration_sec, \
            Tween.TRANS_QUAD, \
            Tween.EASE_IN_OUT)
    hint_tween.interpolate_property( \
            $HeaderWrapper/LockedWrapper/HintWrapper, \
            "modulate:a", \
            1.0, \
            0.0, \
            fade_in_duration_sec, \
            Tween.TRANS_QUAD, \
            Tween.EASE_IN_OUT, \
            HINT_PULSE_DURATION_SEC - fade_in_duration_sec)
    hint_tween.start()

func _on_header_pressed() -> void:
    Global.give_button_press_feedback()
    emit_signal("pressed")

func _on_PlayButton_pressed():
    Global.give_button_press_feedback(true)
    Gs.nav.open(ScreenType.GAME, true)
    Gs.nav.screens[ScreenType.GAME].start_level(level_id)

func _on_accordion_toggled() -> void:
    emit_signal("toggled")

func _on_caret_rotated(rotation: float) -> void:
    $HeaderWrapper/Header/HBoxContainer/CaretWrapper/Caret \
            .rect_rotation = rotation

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
    return $AccordionPanel/VBoxContainer/PlayButton as ShinyButton

func _on_LockedWrapper_gui_input(event: InputEvent) -> void:
    var is_mouse_up: bool = \
            event is InputEventMouseButton and \
            !event.pressed and \
            event.button_index == BUTTON_LEFT
    var is_touch_up: bool = \
            (event is InputEventScreenTouch and \
                    !event.pressed)
    
    if is_mouse_up or is_touch_up:
        _pulse_unlock_hint()
