class_name CharacterSurfaceAnnotator
extends Node2D


var character: SurfacerCharacter

var COLOR := Sc.colors.opacify(
        Sc.colors.character_position, ScaffolderColors.ALPHA_XFAINT)


func _init(character: SurfacerCharacter) -> void:
    self.character = character


func _draw() -> void:
    if character.surface_state.is_grabbing_surface:
        Sc.draw.draw_surface(
                self,
                character.surface_state.grabbed_surface,
                COLOR)


func check_for_update() -> void:
    if character.surface_state.just_changed_surface:
        update()
