class_name CharacterSurfaceAnnotator
extends Node2D


const OPACITY := ScaffolderColors.ALPHA_XFAINT

var character: SurfacerCharacter
var color: Color


func _init(character: SurfacerCharacter) -> void:
    self.character = character
    self.color = Sc.colors.opacify(
            character.position_annotation_color, OPACITY)


func _draw() -> void:
    if character.surface_state.is_grabbing_surface:
        Sc.draw.draw_surface(
                self,
                character.surface_state.grabbed_surface,
                color)


func check_for_update() -> void:
    if character.surface_state.just_changed_surface:
        update()
