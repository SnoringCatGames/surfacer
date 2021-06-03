class_name PathBeatPrediction
extends Node

var time_sec: float
var position: Vector2
var direction: Vector2
var is_downbeat: bool

func _init(
        time_sec: float,
        position: Vector2,
        direction: Vector2,
        is_downbeat: bool) -> void:
    self.time_sec = time_sec
    self.position = position
    self.direction = direction
    self.is_downbeat = is_downbeat
