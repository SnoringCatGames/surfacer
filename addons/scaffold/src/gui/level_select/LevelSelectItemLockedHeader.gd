extends Control
class_name LevelSelectItemLockedHeader

signal unlock_finished

const LOCKED_OPACITY := 0.6
const LOCK_LOW_PART_DELAY_SEC := 0.4
const LOCK_HIGH_PART_DELAY_SEC := 0.15
const HINT_PULSE_DURATION_SEC := 2.0

var is_unlocked := false
var unlock_hint_message: String
var hint_tween: Tween

func _enter_tree() -> void:
    hint_tween = Tween.new()
    $HintWrapper/Hint.add_child(hint_tween)

func update() -> void:
    $HintWrapper/Hint.text = unlock_hint_message
    visible = !is_unlocked
    modulate.a = LOCKED_OPACITY

func pulse_unlock_hint() -> void:
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

func _on_LevelSelectItemLockedHeader_gui_input(event: InputEvent) -> void:
    var is_mouse_up: bool = \
            event is InputEventMouseButton and \
            !event.pressed and \
            event.button_index == BUTTON_LEFT
    var is_touch_up: bool = \
            (event is InputEventScreenTouch and \
                    !event.pressed)
    
    if is_mouse_up or is_touch_up:
        pulse_unlock_hint()

func _on_LockAnimation_unlock_finished():
    emit_signal("unlock_finished")
