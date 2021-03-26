class_name LockAnimation
extends Control

signal unlock_finished

const UNLOCK_DURATION_SEC := 0.8

func _ready() -> void:
    $Control/Node2D/AnimationPlayer.connect( \
            "animation_finished", \
            self, \
            "_on_lock_animation_finished")

func update_gui_scale(gui_scale: float) -> void:
    rect_position.x *= gui_scale
    rect_min_size *= gui_scale
    rect_size *= gui_scale
    $Control.rect_position *= gui_scale
    $Control/Node2D.position *= gui_scale
    $Control/Node2D/Lock.scale *= gui_scale

func play(name: String) -> void:
    assert(name == "Locked" or \
            name == "Unlocked" or \
            name == "Unlock")
    $Control/Node2D/AnimationPlayer.play(name)

func unlock() -> void:
    play("Unlock")

func _on_lock_animation_finished(name: String) -> void:
    if name == "Unlock":
        emit_signal("unlock_finished")
