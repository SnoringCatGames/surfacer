class_name SurfacerCharacterPositionAnnotator
extends ScaffolderCharacterPositionAnnotator


var grab_position_color: Color
var position_along_surface_color: Color


func _init(character: SurfacerCharacter).(character) -> void:
    var position_annotation_color: Color = \
        character.position_annotation_color.sample()
    self.grab_position_color = Color.from_hsv(
            position_annotation_color.h,
            0.7,
            0.9,
            Sc.ann_params.character_grab_position_opacity)
    self.position_along_surface_color = Color.from_hsv(
            position_annotation_color.h,
            0.7,
            0.9,
            Sc.ann_params.character_position_along_surface_opacity)


func _draw() -> void:
    if character.surface_state.is_grabbing_surface:
        _draw_grab_position()
        _draw_position_along_surface()


func _draw_grab_position() -> void:
    var from: Vector2 = character.surface_state.grab_position
    var to: Vector2 = \
            from + \
            character.surface_state.grabbed_surface.normal * \
                    Sc.ann_params.character_grab_position_line_length
    draw_line(
            from,
            to,
            grab_position_color,
            Sc.ann_params.character_grab_position_line_width)


func _draw_position_along_surface() -> void:
    Sc.draw.draw_position_along_surface(
            self,
            character.surface_state.center_position_along_surface,
            position_along_surface_color,
            position_along_surface_color,
            Sc.ann_params.character_position_along_surface_target_point_radius,
            Sc.ann_params.character_position_along_surface_t_length_in_surface,
            Sc.ann_params \
                    .character_position_along_surface_t_length_out_of_surface,
            Sc.ann_params.character_position_along_surface_t_width,
            true,
            false,
            false)
