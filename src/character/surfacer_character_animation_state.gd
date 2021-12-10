class_name SurfacerCharacterAnimationState
extends CharacterAnimationState


var grabbed_surface: Surface
var grab_position: Vector2


func reset() -> void:
    .reset()
    self.grabbed_surface = null
    self.grab_position = Vector2.INF


func copy(other: CharacterAnimationState) -> void:
    .copy(other)
    self.grabbed_surface = other.grabbed_surface
    self.grab_position = other.grab_position
