class_name SurfacerCharacterPositionAnnotator
extends ScaffolderCharacterPositionAnnotator


const GRAB_POSITION_OPACITY := ScaffolderColors.ALPHA_XXFAINT
const GRAB_POSITION_LINE_WIDTH := 5.0
const GRAB_POSITION_LINE_LENGTH := 10.0

const POSITION_ALONG_SURFACE_OPACITY := ScaffolderColors.ALPHA_XXFAINT
const POSITION_ALONG_SURFACE_TARGET_POINT_RADIUS := 4.0
const POSITION_ALONG_SURFACE_T_LENGTH_IN_SURFACE := 0.0
const POSITION_ALONG_SURFACE_T_LENGTH_OUT_OF_SURFACE := 20.0
const POSITION_ALONG_SURFACE_T_WIDTH := 4.0

var grab_position_color: Color
var position_along_surface_color: Color


func _init(character: SurfacerCharacter).(character) -> void:
    self.grab_position_color = Sc.colors.opacify(
            character.position_annotation_color, GRAB_POSITION_OPACITY)
    self.position_along_surface_color = Sc.colors.opacify(
            character.position_annotation_color, POSITION_ALONG_SURFACE_OPACITY)


func _draw() -> void:
    if character.surface_state.is_grabbing_surface:
        _draw_grab_position()
        _draw_position_along_surface()


func _draw_grab_position() -> void:
    var from: Vector2 = character.surface_state.grab_position
    var to: Vector2 = \
            from + \
            character.surface_state.grabbed_surface.normal * \
                    GRAB_POSITION_LINE_LENGTH
    draw_line(
            from,
            to,
            grab_position_color,
            GRAB_POSITION_LINE_WIDTH)


func _draw_position_along_surface() -> void:
    Sc.draw.draw_position_along_surface(
            self,
            character.surface_state.center_position_along_surface,
            position_along_surface_color,
            position_along_surface_color,
            POSITION_ALONG_SURFACE_TARGET_POINT_RADIUS,
            POSITION_ALONG_SURFACE_T_LENGTH_IN_SURFACE,
            POSITION_ALONG_SURFACE_T_LENGTH_OUT_OF_SURFACE,
            POSITION_ALONG_SURFACE_T_WIDTH,
            true,
            false,
            false)
