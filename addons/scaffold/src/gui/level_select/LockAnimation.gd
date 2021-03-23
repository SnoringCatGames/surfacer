extends Control
class_name LockAnimation

signal unlock_finished

const UNLOCK_DURATION_SEC := 0.8

func _ready() -> void:
    $Control/Node2D/AnimationPlayer.connect( \
            "animation_finished", \
            self, \
            "_on_lock_animation_finished")

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
