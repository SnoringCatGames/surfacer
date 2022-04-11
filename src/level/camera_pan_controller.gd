class_name CameraPanController
extends Node2D


const _PAN_AND_ZOOM_INTERVAL := 0.05
const _TWEEN_DURATION := 0.1

var _interval_id := -1
var _tween: ScaffolderTween

var _delta_offset := Vector2.INF
var _delta_zoom_multiplier := INF

var _target_offset := Vector2.ZERO
var _target_zoom_multiplier := 1.0

var _tween_offset := Vector2.ZERO
var _tween_zoom_multiplier := 1.0


func _init() -> void:
    _tween = ScaffolderTween.new()
    add_child(_tween)


func _destroy() -> void:
    Sc.time.clear_interval(_interval_id)


func _validate() -> void:
    Sc.logger.error("Abstract CameraPanController._validate is not implemented")


func _update() -> void:
    if _interval_id < 0:
        _interval_id = Sc.time.set_interval(
                funcref(self, "_update_camera_from_deltas"),
                _PAN_AND_ZOOM_INTERVAL)


func _update_camera_from_deltas() -> void:
    assert(_delta_offset != Vector2.INF)
    assert(!is_inf(_delta_zoom_multiplier))
    
    # Calculate the next values.
    var next_offset := _target_offset + _delta_offset
    var next_zoom_multiplier := \
            _target_zoom_multiplier + _delta_zoom_multiplier if \
            Su.snaps_camera_back_to_character else \
            1.0
    
    # Don't let the pan and zoom exceed their max bounds.
    next_offset.x = clamp(
            next_offset.x,
            -Su.max_pan_distance_from_pointer,
            Su.max_pan_distance_from_pointer)
    next_offset.y = clamp(
            next_offset.y,
            -Su.max_pan_distance_from_pointer,
            Su.max_pan_distance_from_pointer)
    next_zoom_multiplier = clamp(
            next_zoom_multiplier,
            1.0,
            Su.max_zoom_multiplier_from_pointer)
    
    _update_camera(next_offset, next_zoom_multiplier)


func _update_camera(
        next_offset: Vector2,
        next_zoom_multiplier: float) -> void:
    _target_offset = next_offset
    _target_zoom_multiplier = next_zoom_multiplier
    
    # Transition to the new values.
    _tween.stop_all()
    _tween.interpolate_method(
            self,
            "_update_pan",
            _tween_offset,
            next_offset,
            _TWEEN_DURATION,
            "linear",
            0.0,
            TimeType.PLAY_PHYSICS)
    _tween.interpolate_method(
            self,
            "_update_zoom",
            _tween_zoom_multiplier,
            next_zoom_multiplier,
            _TWEEN_DURATION,
            "linear",
            0.0,
            TimeType.PLAY_PHYSICS)
    _tween.start()


func _update_pan(offset: Vector2) -> void:
    var delta := offset - self._tween_offset
    self._tween_offset = offset
    Sc.camera_controller.offset += delta


func _update_zoom(zoom_multiplier: float) -> void:
    var delta := zoom_multiplier - self._tween_zoom_multiplier
    self._tween_zoom_multiplier = zoom_multiplier
    Sc.camera_controller.zoom_factor += delta
