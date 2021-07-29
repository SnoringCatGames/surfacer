class_name PlayerSurfaceAnnotator
extends Node2D


var player: SurfacerPlayer

var COLOR := Sc.colors.opacify(
        Sc.colors.player_position, ScaffolderColors.ALPHA_XFAINT)


func _init(player: SurfacerPlayer) -> void:
    self.player = player


func _draw() -> void:
    if player.surface_state.is_grabbing_a_surface:
        Sc.draw.draw_surface(
                self,
                player.surface_state.grabbed_surface,
                COLOR)


func check_for_update() -> void:
    if player.surface_state.just_changed_surface:
        update()
