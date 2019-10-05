extends Reference
class_name SurfaceCollision

var surface: Surface
var position: Vector2
var player_position: Vector2

func _init(surface: Surface, position: Vector2, player_position: Vector2) -> void:
    self.surface = surface
    self.position = position
    self.player_position = player_position
