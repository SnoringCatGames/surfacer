class_name TransientAnnotator
extends Node2D

signal completed

var duration: float
var delay: float
var ease_name: String
# TimeType
var time_type: int
var updates_every_frame := true

var start_time: float
var current_time: float
var progress := 0.0

func _init(
        duration: float,
        delay := 0.0,
        ease_name := "ease_in_out",
        time_type := TimeType.PLAY_PHYSICS_SCALED) -> void:
    self.start_time = Gs.time.get_elapsed_time(time_type)
    self.current_time = start_time
    self.duration = duration
    self.delay = delay
    self.ease_name = ease_name
    self.time_type = time_type

func _process(_delta: float) -> void:
    _update()

func _update() -> void:
    current_time = Gs.time.get_elapsed_time(time_type)
    
    progress = (current_time - start_time - delay) / duration
    progress = max(progress, 0.0)
    progress = Gs.utils.ease_by_name(progress, ease_name)
    
    if progress >= 1.0:
        emit_signal("completed")
        return
    
    if updates_every_frame:
        update()
