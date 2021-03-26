tool
class_name LevelSelectItem
extends Control

signal toggled
signal pressed

const HEADER_HEIGHT := 56.0
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
    rect_min_size.y = accordion.rect_min_size.y

func _init_children() -> void:
    locked_header = $HeaderWrapper/LevelSelectItemLockedHeader
    unlocked_header = $HeaderWrapper/LevelSelectItemUnlockedHeader
    accordion = $AccordionPanel
    body = $AccordionPanel/LevelSelectItemBody
    
    var header_size := Vector2(rect_min_size.x, HEADER_HEIGHT)
    locked_header.init_children(header_size)
    unlocked_header.init_children(header_size)
    
    accordion.extra_scroll_height_for_custom_header = \
            $HeaderWrapper.rect_size.y

func update() -> void:
    if level_id == "":
        return
    
    locked_header.level_id = level_id
    unlocked_header.level_id = level_id
    body.level_id = level_id
    
    var is_unlocked: bool = \
            Gs.save_state.get_level_is_unlocked(level_id) and \
            !is_new_unlocked_item
    
    locked_header.update_is_unlocked(is_unlocked)
    unlocked_header.update_is_unlocked(is_unlocked)
    accordion.update()
    body.update()
    
    # TODO: Fix this. This hard-coded height assignment shouldn't be needed,
    #       but for some reason the height keeps getting enlarged otherwise.
    accordion.height_override = 268.0

func toggle() -> void:
    if Gs.nav.get_active_screen_name() == "level_select":
        accordion.toggle()

func unlock() -> void:
    unlocked_header.visible = false
    unlocked_header.modulate.a = 0.0
    unlocked_header.unlock()

func _on_unlock_fade_finished(fade_tween: Tween) -> void:
    fade_tween.queue_free()
    locked_header.visible = false
    unlocked_header.visible = true
    emit_signal("pressed")

func _set_level_id(value: String) -> void:
    level_id = value
    update()

func _get_level_id() -> String:
    return level_id

func _set_is_open(value: bool) -> void:
    accordion.is_open = value
    update()

func _get_is_open() -> bool:
    return accordion.is_open

func get_button() -> ShinyButton:
    return body.get_button()

func _on_LevelSelectItemUnlockedHeader_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    emit_signal("pressed")

func _on_AccordionPanel_toggled() -> void:
    emit_signal("toggled")

func _on_AccordionPanel_caret_rotated(rotation: float) -> void:
    unlocked_header.update_caret_rotation(rotation)

func _on_LevelSelectItemLockedHeader_unlock_finished() -> void:
    locked_header.visible = true
    unlocked_header.visible = true
    var fade_tween := Tween.new()
    locked_header.add_child(fade_tween)
    fade_tween.connect( \
            "tween_all_completed", \
            self, \
            "_on_unlock_fade_finished", \
            [fade_tween])
    fade_tween.interpolate_property( \
            locked_header, \
            "modulate:a", \
            LevelSelectItemLockedHeader.LOCKED_OPACITY, \
            0.0, \
            FADE_TWEEN_DURATION_SEC, \
            Tween.TRANS_QUAD, \
            Tween.EASE_IN_OUT)
    fade_tween.interpolate_property( \
            unlocked_header, \
            "modulate:a", \
            0.0, \
            1.0, \
            FADE_TWEEN_DURATION_SEC, \
            Tween.TRANS_QUAD, \
            Tween.EASE_IN_OUT)
    fade_tween.start()
    Gs.time.set_timeout(funcref(Gs.audio, "play_sound"), 0.3, ["achievement"])
