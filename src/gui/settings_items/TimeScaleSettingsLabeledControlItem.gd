class_name TimeScaleSettingsLabeledControlItem
extends SliderLabeledControlItem

const LABEL := "Time scale"
const DESCRIPTION := ""
const MIN_CONTROL_VALUE := -1.0
const MAX_CONTROL_VALUE := 1.0
const MID_CONTROL_VALUE := 0.0
const STEP := (MAX_CONTROL_VALUE - MIN_CONTROL_VALUE) / 32.0
const WIDTH := 128.0
const TICK_COUNT := 3

const MIN_SCALE_VALUE := 0.25
const MAX_SCALE_VALUE := 4.0
const MID_SCALE_VALUE := 1.0


func _init(__ = null).(
        LABEL,
        DESCRIPTION,
        MIN_CONTROL_VALUE,
        MAX_CONTROL_VALUE,
        STEP,
        WIDTH,
        TICK_COUNT
        ) -> void:
    pass


func on_value_changed(control_value: float) -> void:
    var scale_value := _control_value_to_scale_value(control_value)
    Gs.time.additional_debug_time_scale = scale_value
    Gs.save_state.set_setting(
            ScaffolderConfig.ADDITIONAL_DEBUG_TIME_SCALE_SETTINGS_KEY,
            scale_value)


func get_value() -> float:
    return _scale_value_to_control_value(Gs.time.additional_debug_time_scale)


func get_is_enabled() -> bool:
    return true


func _control_value_to_scale_value(control_value: float) -> float:
    if control_value < MID_CONTROL_VALUE:
        var weight := \
                (control_value - MIN_CONTROL_VALUE) / \
                (MID_CONTROL_VALUE - MIN_CONTROL_VALUE)
        return lerp(MIN_SCALE_VALUE, MID_SCALE_VALUE, weight)
    else:
        var weight := \
                (control_value - MID_CONTROL_VALUE) / \
                (MAX_CONTROL_VALUE - MID_CONTROL_VALUE)
        return lerp(MID_SCALE_VALUE, MAX_SCALE_VALUE, weight)


func _scale_value_to_control_value(scale_value: float) -> float:
    if scale_value < MID_SCALE_VALUE:
        var weight := \
                (scale_value - MIN_SCALE_VALUE) / \
                (MID_SCALE_VALUE - MIN_SCALE_VALUE)
        return lerp(MIN_CONTROL_VALUE, MID_CONTROL_VALUE, weight)
    else:
        var weight := \
                (scale_value - MID_SCALE_VALUE) / \
                (MAX_SCALE_VALUE - MID_SCALE_VALUE)
        return lerp(MID_CONTROL_VALUE, MAX_CONTROL_VALUE, weight)
