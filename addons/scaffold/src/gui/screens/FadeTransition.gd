class_name FadeTransition
extends ColorRect

signal fade_complete

var tween: Tween
var duration := 0.3
var is_transitioning := false

func _enter_tree() -> void:
    tween = Tween.new()
    add_child(tween)

func _ready() -> void:
    Gs.utils.connect( \
            "display_resized", \
            self, \
            "_on_resized")
    _on_resized()
    
    _set_cutoff(0)

func _on_resized() -> void:
    rect_size = get_viewport().size

func fade() -> void:
    is_transitioning = true
    _fade_out()

func _fade_out() -> void:
    tween.stop_all()
    if tween.is_connected("tween_completed", self, "_fade_in"):
        tween.disconnect("tween_completed", self, "_fade_in")
    if tween.is_connected("tween_completed", self, "_on_tween_complete"):
        tween.disconnect("tween_completed", self, "_on_tween_complete")
    tween.connect("tween_completed", self, "_fade_in")
    _set_mask(Gs.fade_out_transition_texture)
    tween.interpolate_method( \
            self, \
            "_set_cutoff", \
            1.0, \
            0.0, \
            duration / 2.0, \
            Tween.TRANS_SINE, \
            Tween.EASE_IN)
    tween.start()

func _fade_in( \
        _object: Object, \
        _key: NodePath) -> void:
    tween.stop_all()
    if tween.is_connected("tween_completed", self, "_fade_in"):
        tween.disconnect("tween_completed", self, "_fade_in")
    if tween.is_connected("tween_completed", self, "_on_tween_complete"):
        tween.disconnect("tween_completed", self, "_on_tween_complete")
    tween.connect("tween_completed", self, "_on_tween_complete")
    _set_mask(Gs.fade_in_transition_texture)
    tween.interpolate_method( \
            self, \
            "_set_cutoff", \
            0.0, \
            1.0, \
            duration / 2.0, \
            Tween.TRANS_SINE, \
            Tween.EASE_OUT)
    tween.start()

func _set_mask(value: Texture) -> void:
    material.set_shader_param( \
            "mask", \
            value)

func _set_cutoff(value: float) -> void:
    material.set_shader_param( \
            "cutoff", \
            value)

func _on_tween_complete( \
        _object: Object, \
        _key: NodePath) -> void:
    is_transitioning = false
    emit_signal("fade_complete")
