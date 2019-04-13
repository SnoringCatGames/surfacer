extends Node2D
class_name PlayerSurfaceAnnotator

var player: Player

func _init(player: Player) -> void:
    self.player = player

func _draw() -> void:
    if player.surface_state.is_grabbing_a_surface:
        var color := Color.from_hsv(0.17, 0.7, 0.9, 0.8)
        Utils.draw_surface(self, player.surface_state.grabbed_surface, \
                player.surface_state.grabbed_surface_normal, color)

func check_for_update() -> void:
    if player.surface_state.just_changed_surface:
        update()
