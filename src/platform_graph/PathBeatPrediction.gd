class_name PathBeatPrediction
extends Reference

var time: float
var position: Vector2
var direction: Vector2
var is_downbeat: bool

func _init(
        time: float,
        position: Vector2,
        direction: Vector2,
        is_downbeat: bool) -> void:
    self.time = time
    self.position = position
    self.direction = direction
    self.is_downbeat = is_downbeat
