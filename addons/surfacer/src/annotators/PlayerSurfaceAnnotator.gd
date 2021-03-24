extends Node2D
class_name PlayerSurfaceAnnotator

var player: Player

var COLOR := SurfacerColors.opacify(SurfacerColors.TEAL, SurfacerColors.ALPHA_XFAINT)

func _init(player: Player) -> void:
    self.player = player

func _draw() -> void:
    if player.surface_state.is_grabbing_a_surface:
        Gs.draw_utils.draw_surface( \
                self, \
                player.surface_state.grabbed_surface, \
                COLOR)

func check_for_update() -> void:
    if player.surface_state.just_changed_surface:
        update()
