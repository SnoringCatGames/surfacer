class_name CharacterSurfaceAnnotator
extends Node2D


const OPACITY := ScaffolderColors.ALPHA_XFAINT

var character: SurfacerCharacter
var color: Color


func _init(character: SurfacerCharacter) -> void:
    self.character = character
    self.color = Color.from_hsv(
            character.position_annotation_color.h,
            0.7,
            0.9,
            OPACITY)


func _draw() -> void:
    if character.surface_state.is_grabbing_surface:
        if is_instance_valid(Sc.annotators) and \
                is_instance_valid(Sc.annotators.surfaces_annotator) and \
                Sc.annotators.is_annotator_enabled(AnnotatorType.SURFACES):
            color.a = Sc.annotators.surfaces_annotator.color_params.alpha_max
        else:
            color.a = OPACITY
        
        Sc.draw.draw_surface(
                self,
                character.surface_state.grabbed_surface,
                color)


func check_for_update() -> void:
    if character.surface_state.just_changed_surface:
        if is_instance_valid(Sc.annotators):
            Sc.annotators.surfaces_annotator.exclude(
                    character.surface_state.grabbed_surface,
                    character)
        update()
